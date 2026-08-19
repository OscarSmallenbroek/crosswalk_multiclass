*! Verify that crosswalk_multiclass.pkg declares exactly the files a user needs,
*! and that every table it declares actually loads and runs through crosswalk.
*!
*! The add-on ships only .sthlp data tables and no ado-file, so "installs
*! correctly" reduces to two things: every shipped .sthlp is declared in the
*! .pkg (or -net install- would leave it behind), and every declared file
*! exists and is readable by crosswalk. Both are checked here.
*! Requires crosswalk and moremata; nothing else.
clear all
set more off
set linesize 200

global ROOT "D:/work/multiclass-package"
global SRC  "$ROOT/multiclass-addon"

adopath ++ "$SRC"

local FAIL 0

*=====================================================================
* A. the .pkg declaration matches what is on disk
*=====================================================================
di as txt ""
di as txt "############ A. .pkg DECLARATION ############"

* files the .pkg declares
tempname fh
file open `fh' using "$SRC/crosswalk_multiclass.pkg", read text
local declared ""
file read `fh' line
while r(eof)==0 {
    if regexm(`"`macval(line)'"', "^f[ ]+([^ ]+)[ ]*$") {
        local declared `"`declared' `=regexs(1)'"'
    }
    file read `fh' line
}
file close `fh'
local ndecl : word count `declared'
di as txt "  files declared in the .pkg: " as res `ndecl'

* every declared file must exist
local missing 0
foreach f of local declared {
    capture confirm file "$SRC/`f'"
    if _rc {
        di as err "  declared but missing from disk: `f'"
        local missing = `missing' + 1
    }
}
di as txt "  declared files missing from disk: " as res `missing'
if `missing' local FAIL = `FAIL' + 1

* every shipped .sthlp must be declared
local ondisk : dir "$SRC" files "*.sthlp"
local nd : word count `ondisk'
di as txt "  .sthlp files on disk: " as res `nd'
local undeclared 0
foreach f of local ondisk {
    if !`:list posof `"`f'"' in declared' {
        di as err "  on disk but NOT declared in the .pkg: `f'"
        local undeclared = `undeclared' + 1
    }
}
di as txt "  shipped .sthlp files not declared: " as res `undeclared'
if `undeclared' local FAIL = `FAIL' + 1

*=====================================================================
* B. every declared table loads and runs
*=====================================================================
di as txt ""
di as txt "############ B. EVERY DECLARED TABLE RUNS ############"
set varabbrev off
clear
set obs 5
gen int  isco08  = 5221
gen int  isco88  = 7300
gen byte cwcase  = _n + 1
gen byte sempl   = inlist(_n,1,2,3)
gen byte supvis  = cond(_n==1,10,cond(_n==2,9,cond(_n==4,1,0)))
gen str3 i3      = "522"

di as txt "  -- all 6 employment-relation tables --"
foreach o in isco08 isco88com {
    foreach s in micro meso macro {
        local src = cond("`o'"=="isco08","isco08","isco88")
        capture noisily quietly crosswalk v_`o'_`s' = ///
            mc.`o'_to_`s'(`src' cwcase)
        if _rc {
            di as err "   FAILED mc.`o'_to_`s'() rc=" _rc
            local FAIL = `FAIL' + 1
        }
    }
}
di as txt "  -- the 6 3-digit tables --"
foreach o in isco08 isco88 {
    foreach s in micro meso macro {
        capture noisily quietly crosswalk d_`o'_`s' = ///
            mc.`o'_3_to_`s'(i3 cwcase)
        if _rc {
            di as err "   FAILED mc.`o'_3_to_`s'() rc=" _rc
            local FAIL = `FAIL' + 1
        }
    }
}
di as txt "  -- microclass (ISCO-08 only, no case) --"
capture noisily quietly crosswalk v_microclass = mc.isco08_to_microclass(isco08)
if _rc local FAIL = `FAIL' + 1
di as txt "  -- the case function, and a bare case variable --"
capture noisily quietly crosswalk c1 = mc.isco08_to_micro(isco08 case.mcempstat(sempl supvis))
if _rc local FAIL = `FAIL' + 1
capture noisily quietly crosswalk c2 = mc.isco08_to_micro(isco08 cwcase)
if _rc local FAIL = `FAIL' + 1
set varabbrev on

list cwcase v_isco08_micro v_isco08_meso v_isco08_macro, clean noobs sep(0)

di as txt "  -- all 4 label sets came through --"
foreach s in micro meso macro microclass {
    if "`s'"=="microclass" local v v_microclass
    else                   local v v_isco08_`s'
    local lb : value label `v'
    di as txt "  value label on " %-18s "`v'" ": " as res "`lb'"
    if "`lb'"=="" local FAIL = `FAIL' + 1
}

*=====================================================================
* C. the entry-point help file resolves
*=====================================================================
di as txt ""
di as txt "############ C. ENTRY-POINT HELP ############"
capture findfile crosswalk_multiclass.sthlp
di as txt "  crosswalk_multiclass.sthlp rc = " as res _rc
if _rc local FAIL = `FAIL' + 1

*=====================================================================
di as txt ""
di as txt "#########################################################"
if `FAIL'==0 di as res "  PASS: the declared file set is complete and self-sufficient"
else         di as err "  `FAIL' CHECK(S) FAILED"
di as txt "#########################################################"
assert `FAIL'==0
