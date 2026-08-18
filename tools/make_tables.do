*! Build the multiclass translation tables from the source crosswalk .dta files.
*! Writes build/d_<source>_to_<scheme>.txt, which tools/make_addon.py wraps into
*! the shipped _mcfcn_*.sthlp tables.
clear all
set more off
set linesize 250
capture mkdir "D:/work/multiclass-package/build"
global OUT "D:/work/multiclass-package/build"

*==============================================================
* A. micro -> meso map  (deterministic, 30 rows)
*==============================================================
use "D:/work/multiclass-package/crosswalks/isco08-to-meso.dta", clear
keep microSEC_int mesoSEC
keep if !missing(microSEC_int) & !missing(mesoSEC)
duplicates drop
rename microSEC_int micro
rename mesoSEC meso_m
isid micro
tempfile mesomap
save `mesomap'
di as txt "micro->meso map rows: " _N

*==============================================================
* B. (micro, empstat) -> esecMP map  (deterministic, 59 rows)
*==============================================================
use "D:/work/multiclass-package/crosswalks/isco08-to-meso.dta", clear
keep microSEC_int emp_stat esec08_MP
keep if !missing(microSEC_int) & !missing(esec08_MP)
duplicates drop
rename microSEC_int micro
rename esec08_MP esecmp_m
isid micro emp_stat
tempfile mpmap
save `mpmap'
di as txt "(micro,empstat)->esecmp map rows: " _N

*==============================================================
* helpers
*==============================================================
capture program drop wrblock
program define wrblock
    syntax , KEYvar(name) Scheme(name) Outfile(string)
    preserve
    keep `keyvar' emp_stat `scheme'
    reshape wide `scheme', i(`keyvar') j(emp_stat)
    gsort +`keyvar'
    outfile `keyvar' `scheme'1 `scheme'2 `scheme'3 `scheme'4 `scheme'5 ///
        using "`outfile'", nolabel wide replace
    restore
end

* write a table with a single destination column (schemes that do not vary
* by employment status)
capture program drop wrblock1
program define wrblock1
    syntax , KEYvar(name) Scheme(name) Outfile(string)
    preserve
    keep `keyvar' `scheme'
    duplicates drop
    gsort +`keyvar'
    outfile `keyvar' `scheme' using "`outfile'", nolabel wide replace
    restore
end

* dump the value label attached to a variable, as  value "text"  lines
capture program drop wrlabels
program define wrlabels
    syntax varname , Outfile(string)
    local lbl : value label `varlist'
    if "`lbl'"=="" {
        di as err "no value label attached to `varlist'"
        exit 198
    }
    tempname fh
    file open `fh' using "`outfile'", write text replace
    qui levelsof `varlist', local(vals)
    foreach v of local vals {
        local t : label `lbl' `v'
        file write `fh' `"`v' "`macval(t)'""' _n
    }
    file close `fh'
    di as txt "  wrote " `:word count `vals'' " labels from value label {bf:`lbl'}"
end

* assert that `level' determines esec, i.e. the schema nests
capture program drop nestcheck
program define nestcheck
    syntax , Level(name) Tag(string)
    preserve
    keep if !missing(`level') & !missing(esec)
    keep `level' esec
    duplicates drop
    bysort `level': gen byte _n2 = _N
    qui count if _n2>1
    if r(N) {
        di as err "  `tag': `level' -> esec is NOT single valued (" r(N) " cases)"
        list if _n2>1, clean noobs sep(0)
    }
    else di as txt "  `tag': " as res "`level'" as txt " -> esec is single valued"
    assert _n2==1
    restore
end

* Resolve every 3-digit code crosswalk's own 4-digit -> 3-digit collapse can
* emit, through the same minor -> sub-major -> major fallback the lookup uses,
* and write it as build/addon3_<version>.csv for tools/make_addon.py.
*
* The fallback is on the KEY, not on the cell: if a minor group is present in
* the table at all, its row is used even where individual employment-status
* cells are missing. Only a minor group absent from the table falls back to
* its sub-major group, and then to its major group. Getting that distinction
* wrong silently changes which codes come back uncoded.
*
* This is done here, rather than by a separate command, so that the add-on can
* be rebuilt from the source .dta files with nothing but Stata and crosswalk.
capture program drop resolve3
program define resolve3
    syntax , KEYvar(name) Version(string) Outfile(string)
    preserve
    keep `keyvar' emp_stat micro meso esec esecmp
    rename `keyvar' kk
    tempfile tab
    qui save `tab'

    * distinct keys, to test key existence independently of cell contents
    keep kk
    qui duplicates drop
    gen byte exists = 1
    tempfile keys
    qui save `keys'

    * the 3-digit codes crosswalk's own collapse table can produce
    crosswalk import `version'_to_`version'_3(), clear
    qui ds
    local c2 : word 2 of `r(varlist)'
    keep `c2'
    rename `c2' code3str
    qui destring code3str, gen(code3) force
    qui drop if missing(code3)
    qui duplicates drop
    qui expand 5
    bysort code3: gen byte emp_stat = _n
    gen long k = code3*10

    * which of the three key levels exist in the table
    gen long kk = k
    qui merge m:1 kk using `keys', keep(master match) nogen
    gen byte has1 = exists==1
    drop exists kk
    gen long kk = int(k/100)*100
    qui merge m:1 kk using `keys', keep(master match) nogen
    gen byte has2 = exists==1
    drop exists kk
    gen long kk = int(k/1000)*1000
    qui merge m:1 kk using `keys', keep(master match) nogen
    gen byte has3 = exists==1
    drop exists kk

    * most specific level that exists wins
    gen long kk = .
    replace kk = int(k/1000)*1000 if has3
    replace kk = int(k/100)*100   if has2
    replace kk = k                if has1
    qui merge m:1 kk emp_stat using `tab', keep(master match) nogen

    foreach s in micro meso esec esecmp {
        rename `s' mc_`s'
    }
    qui count if has1
    di as txt "  `version': rows matched at minor level    : " r(N)
    qui count if !has1 & has2
    di as txt "  `version': rows filled from sub-major     : " r(N)
    qui count if !has1 & !has2 & has3
    di as txt "  `version': rows filled from major         : " r(N)
    qui count if !has1 & !has2 & !has3
    di as txt "  `version': rows with no key at any level  : " r(N)

    keep code3 emp_stat mc_micro mc_meso mc_esec mc_esecmp
    order code3 emp_stat mc_micro mc_meso mc_esec mc_esecmp
    sort code3 emp_stat
    export delimited using "`outfile'", replace nolabel datafmt
    restore
end

* collapse esecmp (11) into esec (9)
capture program drop mkesec
program define mkesec
    syntax , Gen(name) From(name)
    gen byte `gen' = .
    replace `gen' = 1 if inlist(`from',1,2)
    replace `gen' = 2 if inlist(`from',3,4)
    replace `gen' = 3 if `from'==5
    replace `gen' = 4 if `from'==6
    replace `gen' = 5 if `from'==7
    replace `gen' = 6 if `from'==8
    replace `gen' = 7 if `from'==9
    replace `gen' = 8 if `from'==10
    replace `gen' = 9 if `from'==11
end

*==============================================================
* C. ISCO-08 tables
*==============================================================
use "D:/work/multiclass-package/crosswalks/isco08-to-meso.dta", clear
keep ISCO08 emp_stat microSEC_int esec08_MP mesoSEC
rename microSEC_int micro
rename mesoSEC meso
rename esec08_MP esecmp
label drop _all

merge m:1 micro using `mesomap', keep(1 3) nogen
replace meso = meso_m if missing(meso) & !missing(meso_m)
drop meso_m
merge m:1 micro emp_stat using `mpmap', keep(1 3) nogen
replace esecmp = esecmp_m if missing(esecmp) & !missing(esecmp_m)
drop esecmp_m

mkesec, gen(esec) from(esecmp)

* Put ISCO-08 keys on the same 4-digit right-padded convention as the
* ISCO-88com tables (111 -> 1110, 11 -> 0110), so every shipped table uses one
* key convention and 4-digit unit-group keys remain expressible.
gen long isco4 = ISCO08*10

di as txt "==== ISCO08: N rows (want 910), unique keys (want 182) ===="
count
codebook isco4, compact
di as txt "==== ISCO08 coverage ===="
foreach v in micro meso esec esecmp {
    qui count if !missing(`v')
    di as txt "  `v': " r(N)
}
isid isco4 emp_stat

di as txt "==== ISCO08 nesting: micro / meso / esecmp must each determine esec ===="
nestcheck, level(micro)  tag(isco08)
nestcheck, level(meso)   tag(isco08)
nestcheck, level(esecmp) tag(isco08)

wrblock, keyvar(isco4) scheme(micro)  outfile("$OUT/d_isco08_to_micro.txt")
wrblock, keyvar(isco4) scheme(meso)   outfile("$OUT/d_isco08_to_meso.txt")
wrblock, keyvar(isco4) scheme(esec)   outfile("$OUT/d_isco08_to_esec.txt")
wrblock, keyvar(isco4) scheme(esecmp) outfile("$OUT/d_isco08_to_esecmp.txt")

di as txt "==== ISCO08: resolving 3-digit codes for the add-on ===="
resolve3, keyvar(isco4) version(isco08) outfile("$OUT/addon3_isco08.csv")

*==============================================================
* D. ISCO-88com tables
*==============================================================
use "D:/work/multiclass-package/crosswalks/isco88com to MSECS v2 FINAL.dta", clear
keep isco88com emp_stat msecs_int esec88
rename msecs_int micro
rename esec88 esec
label drop _all

*--------------------------------------------------------------
* Two occupation-by-status cells carry a micro-class that does not
* aggregate to their own native ESeC class, which breaks the nesting of
* the schema. In both cases the cell is also out of step with the other
* employment statuses of the same ISCO code. Reassigned so that
* micro -> meso -> ESeC and micro -> ESeC-MP -> ESeC both hold:
*
*   2400 self-employed : Cultural associate professionals (42)
*                        -> Business operation professionals (20)
*                        -> meso 21 -> ESeC 1   (matches esec88, and the
*                           employee row of 2400, which is already micro 20)
*   7300 employees     : Industrial workers (102)
*                        -> Technical supervisors (80)
*                        -> meso 46 -> ESeC 6   (matches esec88, and the
*                           supervisor row of 7300, which is already micro 80)
*--------------------------------------------------------------
di as txt "==== reassigning the two non-nesting cells ===="
qui count if isco88com==2400 & emp_stat==3 & micro==42
di as txt "  2400 self-employed with micro 42: " r(N) " row(s)"
assert r(N)==1
qui count if isco88com==7300 & emp_stat==5 & micro==102
di as txt "  7300 employees with micro 102   : " r(N) " row(s)"
assert r(N)==1
replace micro = 20 if isco88com==2400 & emp_stat==3
replace micro = 80 if isco88com==7300 & emp_stat==5

merge m:1 micro using `mesomap', keep(1 3) nogen
rename meso_m meso
merge m:1 micro emp_stat using `mpmap', keep(1 3) nogen
rename esecmp_m esecmp

di as txt "==== ISCO88com: N rows (want 730), unique keys (want 146) ===="
count
codebook isco88com, compact
di as txt "==== ISCO88com coverage ===="
foreach v in micro meso esec esecmp {
    qui count if !missing(`v')
    di as txt "  `v': " r(N)
}
isid isco88com emp_stat

di as txt "==== ISCO88com nesting ===="
nestcheck, level(micro)  tag(isco88com)
nestcheck, level(meso)   tag(isco88com)
nestcheck, level(esecmp) tag(isco88com)

di as txt "==== ISCO88com: collapse(esecmp) must reproduce native esec88 ===="
mkesec, gen(esec_c) from(esecmp)
qui count if !missing(esec_c) & !missing(esec) & esec_c!=esec
di as txt "  disagreements: " as res r(N)
if r(N) {
    list isco88com emp_stat micro esecmp esec_c esec ///
        if !missing(esec_c) & !missing(esec) & esec_c!=esec, clean noobs sep(0)
}
assert esec_c==esec if !missing(esec_c) & !missing(esec)
drop esec_c

wrblock, keyvar(isco88com) scheme(micro)  outfile("$OUT/d_isco88com_to_micro.txt")
wrblock, keyvar(isco88com) scheme(meso)   outfile("$OUT/d_isco88com_to_meso.txt")
wrblock, keyvar(isco88com) scheme(esec)   outfile("$OUT/d_isco88com_to_esec.txt")
wrblock, keyvar(isco88com) scheme(esecmp) outfile("$OUT/d_isco88com_to_esecmp.txt")

di as txt "==== ISCO88com: resolving 3-digit codes for the add-on ===="
resolve3, keyvar(isco88com) version(isco88) outfile("$OUT/addon3_isco88.csv")

*==============================================================
* E. ISCO-08 micro-class scheme (Barone, Hertel and Smallenbroek)
*    77 categories. Purely occupational: it does not vary by employment
*    status, so the table gets a single destination column. Keys are
*    4-digit ISCO-08 codes right-padded with zeros, down to unit-group
*    (4-digit) level, so the table is written as-is.
*==============================================================
use "D:/work/multiclass-package/crosswalks/isco08 to microclass.dta", clear
keep isco08 micro_class
rename isco08 isco4
rename micro_class microclass
label drop _all

di as txt "==== microclass: N rows (want 589), classes (want 77) ===="
count
codebook isco4 microclass, compact
isid isco4
qui levelsof microclass, local(mcvals)
di as txt "  distinct micro-classes: " as res `:word count `mcvals''
assert `:word count `mcvals'' == 77
qui count if missing(microclass)
di as txt "  rows with a missing class: " as res r(N)
assert r(N)==0

di as txt "==== microclass key digit structure ===="
gen byte ndig = strlen(string(isco4))
tab ndig
drop ndig

wrblock1, keyvar(isco4) scheme(microclass) outfile("$OUT/d_isco08_to_microclass.txt")

* the micro08 value label is authoritative: the string variable in the source
* carries two spellings for codes 752 and 810
use "D:/work/multiclass-package/crosswalks/isco08 to microclass.dta", clear
wrlabels micro_class, outfile("$OUT/labels_microclass.txt")

di as txt "==== DONE ===="
