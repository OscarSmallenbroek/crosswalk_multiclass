*! Live end-to-end test of the crosswalk_multiclass add-on.
*!
*! Everything here is executed by crosswalk itself. The ONLY dependencies are
*! crosswalk (Ben Jann, SSC), moremata, and this add-on -- there is no other
*! command to compare against and no Python in the loop. That is deliberate:
*! crosswalk_multiclass is a data-only add-on for crosswalk, so crosswalk is
*! both the thing under test and the only oracle a user has.
*!
*! The grid runs over crosswalk's own 1-6 case numbering, not the 1-5 scale the
*! source files use: the add-on exposes only the standard 6-column case, so
*! case 1 (employment status unknown) is part of what must be tested.
*!
*! Three kinds of check, none needing anything outside crosswalk:
*!   1. INTERNAL CONSISTENCY -- the several routes crosswalk offers to the same
*!      answer must all agree.
*!   2. EXTERNAL PARITY -- collapsing our Macro-SEC must reproduce crosswalk's own
*!      native isco88_to_esec()/isco08_to_esec() exactly. A real external check:
*!      crosswalk's ESeC comes from the Harrison/Rose matrix, ours from the
*!      MicroSEC files.
*!   3. STRUCTURE -- the schemes must nest, and must fail safe on bad input.
clear all
set more off
set linesize 200

adopath ++ "D:/work/multiclass-package/multiclass-addon"

local FAIL 0

*=====================================================================
* A. dependencies
*=====================================================================
di as txt ""
di as txt "############ A. DEPENDENCIES ############"
capture which crosswalk
if _rc {
    di as err "crosswalk not found -- ssc install crosswalk"
    exit 601
}
capture findfile lmoremata.mlib
di as txt "  lmoremata.mlib rc = " _rc
if _rc {
    di as err "moremata not found -- ssc install moremata"
    exit 601
}
clear
set obs 1
gen int isco = 1110
gen byte sempl  = 0
gen byte supvis = 0
capture noisily crosswalk probe = mc.isco08_to_micro(isco case.mcempstat(sempl supvis))
if _rc {
    di as err "crosswalk could not run the add-on (rc = " _rc ")"
    exit _rc
}
di as txt "  crosswalk + add-on load OK; probe = " probe[1] " (expected 10)"
assert probe[1]==10

* the removed case.mcstatus5() must really be gone
capture quietly crosswalk gone = mc.isco08_to_micro(isco case.mcstatus5(sempl))
di as txt "  case.mcstatus5() rc = " as res _rc as txt " (nonzero expected: removed)"
if _rc==0 {
    di as err "  case.mcstatus5() still resolves; it should have been removed"
    local FAIL = `FAIL' + 1
}

*=====================================================================
* B. crosswalk can read every shipped table itself
*=====================================================================
di as txt ""
di as txt "############ B. EVERY SHIPPED TABLE LOADS ############"
foreach f in mc_isco88com_to_micro mc_isco88com_to_meso mc_isco88com_to_macro ///
             mc_isco08_to_micro   mc_isco08_to_meso   mc_isco08_to_macro   ///
             mc_isco88_3_to_micro mc_isco88_3_to_meso mc_isco88_3_to_macro ///
             mc_isco08_3_to_micro mc_isco08_3_to_meso mc_isco08_3_to_macro ///
             mc_isco08_to_microclass {
    capture quietly crosswalk list `f'()
    local rc = _rc
    di as txt "  crosswalk list " %-26s "`f'()" "  rc = " as res `rc' ///
        as txt "   rows = " as res r(r)
    if `rc' local FAIL = `FAIL' + 1
}
capture noisily crosswalk dir
di as txt "  crosswalk dir rc = " _rc
if _rc local FAIL = `FAIL' + 1

*=====================================================================
* C. FULL-GRID INTERNAL CONSISTENCY
*    Every 4-digit code crosswalk's own collapse table can emit, x all 6
*    cases, x the 3 employment-relation schemes, x both ISCO versions.
*    Four routes to the same cell must agree:
*      cwn  4-digit wrapper, numeric key, case variable
*      cws  4-digit wrapper, STRING key (zero padded), case variable
*      cwf  4-digit wrapper, case built by case.mcempstat() from sempl/supvis
*      cw3  3-digit table applied to crosswalk's own collapsed code
*    cw3 is the one that matters most: it checks the 3-digit table carries a
*    row for every code isco88_to_isco88_3()/isco08_to_isco08_3() can produce.
*=====================================================================
foreach v in isco08 isco88 {
    if "`v'"=="isco08" {
        local orig  isco08
    }
    else {
        local orig  isco88com
    }
    di as txt ""
    di as txt "############ C. FULL GRID: `v' ############"

    crosswalk import `v'_to_`v'_3(), clear
    qui ds
    local k1 : word 1 of `r(varlist)'
    local k2 : word 2 of `r(varlist)'
    rename `k1' isco4str
    rename `k2' isco3str
    qui destring isco4str, gen(isco4num) force
    qui drop if missing(isco4num)
    qui duplicates drop
    local ncodes = _N
    qui expand 6
    bysort isco4num: gen byte cwcase = _n

    * sempl/supvis that reproduce each case through case.mcempstat():
    *   1 sempl missing | 2 empl,no sup | 3 empl,sup
    *   4 self,0 empl   | 5 self,1-9    | 6 self,10+
    gen byte sempl  = .
    gen byte supvis = .
    replace sempl  = 0  if inlist(cwcase,2,3)
    replace sempl  = 1  if inlist(cwcase,4,5,6)
    replace supvis = 0  if cwcase==2
    replace supvis = 1  if cwcase==3
    replace supvis = 0  if cwcase==4
    replace supvis = 1  if cwcase==5
    replace supvis = 10 if cwcase==6
    di as txt "  4-digit codes from `v'_to_`v'_3(): " as res `ncodes' ///
        as txt "   rows: " as res _N

    foreach s in micro meso macro {
        qui crosswalk cwn_`s' = mc.`orig'_to_`s'(isco4num cwcase)
        qui crosswalk cws_`s' = mc.`orig'_to_`s'(isco4str cwcase)
        qui crosswalk cwf_`s' = mc.`orig'_to_`s'(isco4num case.mcempstat(sempl supvis))
        qui crosswalk cw3_`s' = mc.`v'_3_to_`s'(isco3str cwcase)
    }

    foreach s in micro meso macro {
        local bad 0
        foreach r in cws cwf cw3 {
            qui count if !((`r'_`s'==cwn_`s') | (missing(`r'_`s') & missing(cwn_`s')))
            local bad = `bad' + r(N)
        }
        qui count if !missing(cwn_`s')
        di as txt "  " %-7s "`s'" "  coded=" as res %6.0f r(N) ///
            as txt "   disagreements across the 4 routes = " as res %4.0f `bad'
        if `bad' {
            local FAIL = `FAIL' + 1
            list isco4str isco3str cwcase cwn_`s' cws_`s' cwf_`s' cw3_`s' ///
                if !((cws_`s'==cwn_`s') | (missing(cws_`s') & missing(cwn_`s'))) ///
                 | !((cwf_`s'==cwn_`s') | (missing(cwf_`s') & missing(cwn_`s'))) ///
                 | !((cw3_`s'==cwn_`s') | (missing(cw3_`s') & missing(cwn_`s'))), ///
                clean noobs sep(0) nolabel
        }
    }

    * case 1 is the unknown column and must be missing everywhere
    foreach s in micro meso macro {
        qui count if cwcase==1 & !missing(cwn_`s')
        if r(N) {
            di as err "  case 1 (unknown) returned a class for `s' in " r(N) " rows"
            local FAIL = `FAIL' + 1
        }
    }
    di as txt "  case 1 (unknown) is missing in all 3 schemes: " ///
        as res cond(`FAIL'==0,"yes","NO")

    *-----------------------------------------------------------------
    * D. EXTERNAL PARITY + NESTING, on the same grid
    *    Native isco88_to_esec() takes case.esec88(), the same 1-6 numbering
    *    used here. Native isco08_to_esec() takes case.esec(), a DIFFERENT
    *    5-column numbering with no "unknown" case, so it is shifted by one.
    *    Passing the wrong one silently selects wrong columns.
    *-----------------------------------------------------------------
    if "`v'"=="isco08" {
        local nativefn  isco08_to_esec
        gen byte nativecase = cwcase - 1
    }
    else {
        local nativefn  isco88_to_esec
        gen byte nativecase = cwcase
    }
    qui crosswalk esec_native = `nativefn'(isco4num nativecase)

    gen byte esec_c = .
    replace esec_c = 1 if inlist(cwn_macro,1,2)
    replace esec_c = 2 if inlist(cwn_macro,3,4)
    replace esec_c = 3 if cwn_macro==5
    replace esec_c = 4 if cwn_macro==6
    replace esec_c = 5 if cwn_macro==7
    replace esec_c = 6 if cwn_macro==8
    replace esec_c = 7 if cwn_macro==9
    replace esec_c = 8 if cwn_macro==10
    replace esec_c = 9 if cwn_macro==11

    qui count if !missing(esec_c) & !missing(esec_native)
    local comparable = r(N)
    qui count if !missing(esec_c) & !missing(esec_native) & esec_c!=esec_native
    local disagree = r(N)
    di as txt "  D1 collapse(macro) vs `nativefn'(): comparable=" as res `comparable' ///
        as txt "  disagree=" as res `disagree'
    if `disagree' {
        local FAIL = `FAIL' + 1
        di as err "  `v': collapse(macro) no longer reproduces crosswalk's native ESeC"
        list isco4str cwcase cwn_macro esec_c esec_native ///
            if !missing(esec_c) & !missing(esec_native) & esec_c!=esec_native, ///
            clean noobs sep(0) nolabel
    }

    foreach s in micro meso macro {
        preserve
        qui keep if !missing(cwn_`s') & !missing(esec_c)
        keep cwn_`s' esec_c
        qui duplicates drop
        bysort cwn_`s': gen byte _n2 = _N
        qui count if _n2>1
        di as txt "  D2 `v': " %-7s "`s'" " -> esec single valued: " ///
            as res cond(r(N)==0,"yes","NO (" + strofreal(r(N)) + " cases)")
        if r(N) {
            local FAIL = `FAIL' + 1
            list if _n2>1, clean noobs sep(0) nolabel
        }
        restore
    }
}

*=====================================================================
* E. the micro-class table: no case, ISCO-08 only, 4-digit resolution
*=====================================================================
di as txt ""
di as txt "############ E. mc.isco08_to_microclass() ############"
crosswalk import isco08_to_isco08_3(), clear
qui ds
local k : word 1 of `r(varlist)'
keep `k'
rename `k' isco4str
qui destring isco4str, gen(isco08) force
qui drop if missing(isco08)
qui duplicates drop
qui crosswalk mcl = mc.isco08_to_microclass(isco08)
qui count if !missing(mcl)
di as txt "  4-digit ISCO-08 codes coded: " as res r(N) as txt " of " as res _N
qui levelsof mcl, local(lv)
di as txt "  distinct micro-classes returned: " as res `:word count `lv''

di as txt "  -- unit-group detail must survive (1111 and 1120 must differ) --"
clear
set obs 4
gen int isco08 = .
replace isco08 = 1111 in 1
replace isco08 = 1120 in 2
replace isco08 = 7549 in 3
replace isco08 = 0110 in 4
qui crosswalk u = mc.isco08_to_microclass(isco08)
list isco08 u, clean noobs sep(0) nolabel
assert u[1]!=u[2]
di as txt "  OK: resolves at unit-group level, not minor-group level"

*=====================================================================
* F. value labels arrive from labels_mc_*
*=====================================================================
di as txt ""
di as txt "############ F. VALUE LABELS ############"
clear
set obs 5
gen int isco08 = 5221
gen byte cwcase = _n + 1
foreach s in micro meso macro {
    qui crosswalk L_`s' = mc.isco08_to_`s'(isco08 cwcase)
    local lb : value label L_`s'
    qui levelsof L_`s', local(lv)
    di as txt "  L_`s': value label = " as res "`lb'" ///
        as txt "   distinct labelled values = " as res `:word count `lv''
    if "`lb'"=="" {
        di as err "  no value label attached"
        local FAIL = `FAIL' + 1
    }
}
qui crosswalk L_microclass = mc.isco08_to_microclass(isco08)
local lb : value label L_microclass
di as txt "  L_microclass: value label = " as res "`lb'"
if "`lb'"=="" {
    di as err "  no value label attached"
    local FAIL = `FAIL' + 1
}
list cwcase L_micro L_meso L_macro, clean noobs sep(0)
di as txt "  (5221 = shopkeepers; the five cases must differ)"
qui levelsof L_micro, local(lv)
assert `:word count `lv'' == 5

*=====================================================================
* G. case.mcempstat()
*=====================================================================
di as txt ""
di as txt "############ G. case.mcempstat() ############"
clear
set obs 8
gen byte sempl  = .
gen byte supvis = .
replace sempl = 1  in 1
replace supvis= 25 in 1
replace sempl = 1  in 2
replace supvis= 9  in 2
replace sempl = 1  in 3
replace supvis= 1  in 3
replace sempl = 1  in 4
replace supvis= 0  in 4
replace sempl = 0  in 5
replace supvis= 3  in 5
replace sempl = 0  in 6
replace supvis= 0  in 6
replace sempl = 0  in 7
replace supvis= .  in 7
replace sempl = .  in 8
gen int isco08 = 2411

foreach s in micro meso macro {
    qui crosswalk cf_`s' = mc.isco08_to_`s'(isco08 case.mcempstat(sempl supvis))
}
list sempl supvis cf_micro cf_meso cf_macro, clean noobs sep(0) nolabel

di as txt "  -- sempl missing must be UNCODED, not silently column 1 --"
assert missing(cf_micro) in 8
assert missing(cf_meso)  in 8
assert missing(cf_macro) in 8
di as txt "  OK"

* case.esec88() uses the same 1-6 numbering and must be interchangeable
foreach s in micro meso macro {
    qui crosswalk e88_`s' = mc.isco08_to_`s'(isco08 case.esec88(sempl supvis))
    qui count if !((e88_`s'==cf_`s') | (missing(e88_`s') & missing(cf_`s')))
    di as txt "  case.esec88() vs case.mcempstat() differences (`s'): " as res r(N)
    if r(N) local FAIL = `FAIL' + 1
}

di as txt "  -- supvis omitted must still code --"
qui crosswalk nos_micro = mc.isco08_to_micro(isco08 case.mcempstat(sempl))
qui count if !missing(nos_micro)
di as txt "  coded rows with supvis omitted: " as res r(N) as txt " of 8"
if r(N)==0 local FAIL = `FAIL' + 1

*=====================================================================
* H. invalid codes and invalid cases must fail safe
*=====================================================================
di as txt ""
di as txt "############ H. INVALID CODES AND CASES ############"
clear
set obs 9
gen double isco08 = .
replace isco08 = -1     in 1
replace isco08 = 0      in 2
replace isco08 = 99     in 3
replace isco08 = 10000  in 4
replace isco08 = 123456 in 5
replace isco08 = .      in 6
replace isco08 = 2411   in 7
replace isco08 = 2411   in 8
replace isco08 = 2411   in 9
gen byte cwcase = 2
replace cwcase = 9 in 8
replace cwcase = . in 9
qui crosswalk iv = mc.isco08_to_micro(isco08 cwcase)
list isco08 cwcase iv, clean noobs sep(0) nolabel
di as txt "  rows 1-6 (bad code) must be missing; 8 and 9 (bad case) fall to"
di as txt "  column 1, which is the unknown column and is missing throughout"
assert missing(iv) in 1/6
assert missing(iv) in 8
assert missing(iv) in 9
assert iv[7]==20
di as txt "  OK"

di as txt "  -- 3-digit table edge keys --"
clear
set obs 10
gen str3 isco3 = ""
replace isco3 = "111" in 1
replace isco3 = "011" in 2
replace isco3 = "261" in 3
replace isco3 = "532" in 4
replace isco3 = "112" in 5
replace isco3 = "933" in 6
replace isco3 = "999" in 7
replace isco3 = "000" in 8
replace isco3 = "324" in 9
replace isco3 = "515" in 10
gen byte cwcase = 2
qui crosswalk d08 = mc.isco08_3_to_micro(isco3 cwcase)
qui crosswalk d88 = mc.isco88_3_to_micro(isco3 cwcase)
list isco3 d08 d88, clean noobs sep(0) nolabel
di as txt "  (999 and 000 are not ISCO codes and must be missing)"
assert missing(d08) in 7
assert missing(d08) in 8
assert missing(d88) in 7
assert missing(d88) in 8

*=====================================================================
di as txt ""
di as txt "#########################################################"
if `FAIL'==0 di as res "  ALL LIVE ADD-ON TESTS PASSED (crosswalk only)"
else         di as err "  `FAIL' CHECK(S) FAILED"
di as txt "#########################################################"
assert `FAIL'==0
