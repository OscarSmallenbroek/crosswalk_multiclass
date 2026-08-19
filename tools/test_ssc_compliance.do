*! SSC compliance checks for crosswalk_multiclass.
*! http://repec.org/bocode/s/sscsubmit.html
*!  - all materials must work with -set varabbrev off-
*!  - command names strictly lower case, no reserved graphics words
*!  - every ado-file carries a -version- statement
*!
*! This package is data-only: it ships no ado-file and defines no command, so
*! the command-name and -version- requirements are satisfied vacuously and the
*! substantive check is that every table behaves under -set varabbrev off-.
*! Everything here runs through crosswalk; nothing else is required.
clear all
set more off
set linesize 200

adopath ++ "D:/work/multiclass-package/multiclass-addon"

local FAIL 0

*=====================================================================
* A. varabbrev off
*    Variables are deliberately named so that any accidental reliance on
*    abbreviation picks the wrong variable or errors out.
*=====================================================================
di as txt ""
di as txt "############ A. set varabbrev off ############"
set varabbrev off
di as txt "  varabbrev is now: " as res "`c(varabbrev)'"

clear
set obs 5
gen int  isco          = 5221
gen int  isco08        = 2411
gen int  isco08extra   = 9999
gen byte emp           = _n
gen byte cwcase        = _n + 1
gen byte cwcasefull    = _n + 1
gen byte sempl         = inlist(_n,1,2,3)
gen byte semplx        = 0
gen byte supvis        = cond(_n==1,10,cond(_n==2,9,cond(_n==4,1,0)))
gen byte supvisx       = 0

di as txt "  -- all 6 employment-relation tables --"
foreach o in isco08 isco88com {
    foreach s in micro meso macro {
        capture noisily quietly crosswalk cw_`o'_`s' = ///
            mc.`o'_to_`s'(isco08 cwcase)
        if _rc {
            di as err "  FAILED mc.`o'_to_`s'() rc=" _rc
            local FAIL = `FAIL' + 1
        }
    }
}
di as txt "  -- the 6 3-digit tables --"
gen str3 isco3 = "241"
foreach o in isco08 isco88 {
    foreach s in micro meso macro {
        capture noisily quietly crosswalk d_`o'_`s' = ///
            mc.`o'_3_to_`s'(isco3 cwcase)
        if _rc {
            di as err "  FAILED mc.`o'_3_to_`s'() rc=" _rc
            local FAIL = `FAIL' + 1
        }
    }
}
di as txt "  -- microclass (ISCO-08 only, no case) --"
capture noisily quietly crosswalk cw_microclass = mc.isco08_to_microclass(isco08)
if _rc {
    di as err "  FAILED mc.isco08_to_microclass() rc=" _rc
    local FAIL = `FAIL' + 1
}
di as txt "  -- the case function, with and without supvis --"
capture noisily quietly crosswalk cf1 = mc.isco08_to_micro(isco08 case.mcempstat(sempl supvis))
if _rc {
    di as err "  FAILED case.mcempstat() rc=" _rc
    local FAIL = `FAIL' + 1
}
capture noisily quietly crosswalk cf2 = mc.isco08_to_micro(isco08 case.mcempstat(sempl))
if _rc {
    di as err "  FAILED case.mcempstat() without supvis rc=" _rc
    local FAIL = `FAIL' + 1
}
di as txt "  -- crosswalk's own native ESeC (not duplicated in the add-on) --"
foreach f in isco08_to_esec isco88_to_esec {
    capture noisily quietly crosswalk cw_`f' = `f'(isco08 emp)
    if _rc {
        di as err "  FAILED `f'() rc=" _rc
        local FAIL = `FAIL' + 1
    }
}

* the same calls must give the same answers with abbreviation back on
tempfile off
qui save `off'
set varabbrev on
di as txt "  varabbrev restored to: " as res "`c(varabbrev)'"
foreach o in isco08 isco88com {
    foreach s in micro meso macro {
        qui crosswalk on_`o'_`s' = mc.`o'_to_`s'(isco08 cwcase)
        qui count if !((on_`o'_`s'==cw_`o'_`s') | ///
            (missing(on_`o'_`s') & missing(cw_`o'_`s')))
        if r(N) {
            di as err "  varabbrev changed the answer for mc.`o'_to_`s'()"
            local FAIL = `FAIL' + 1
        }
    }
}
di as txt "  results identical with varabbrev on and off: " ///
    as res cond(`FAIL'==0,"yes","NO")

*=====================================================================
* B. the package defines no command name
*=====================================================================
di as txt ""
di as txt "############ B. NO COMMAND NAME ############"
di as txt "  The add-on ships only .sthlp files, so there is no command name to"
di as txt "  collide with a reserved word and no ado-file to carry a -version-"
di as txt "  statement. Minimum Stata version 14 is inherited from crosswalk."
capture which crosswalk_multiclass.ado
di as txt "  which crosswalk_multiclass.ado rc = " as res _rc ///
    as txt " (nonzero expected: no ado-file)"
if _rc==0 {
    di as err "  an ado-file exists; the SSC checks above no longer apply"
    local FAIL = `FAIL' + 1
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
if `FAIL'==0 di as res "  ALL SSC COMPLIANCE CHECKS PASSED"
else         di as err "  `FAIL' CHECK(S) FAILED"
di as txt "#########################################################"
assert `FAIL'==0
