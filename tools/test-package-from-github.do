* Testing out the crosswalk package as downloaded from github. 

net install crosswalk_multiclass, from("https://raw.githubusercontent.com/OscarSmallenbroek/crosswalk_multiclass/master/multiclass-addon") replace


*create all possible isco08 codes
clear
set obs 9999
gen isco08 = _n
iscolbl isco08 isco08 , minor
decode isco08, gen(isco08_str)
drop if isco08_str == ""
compress

* create 6 employment status. 
expand 6
bysort isco08: gen selfemp= (_n > 3)
bysort isco08: gen nsuperv=  (_n == 3)
bysort isco08: replace nsuperv= 9 if _n == 5
bysort isco08: replace nsuperv= 10 if _n == 6
sum 
global obs = `r(N)'
*create 4 digit isco08 codes. 
gen isco08_4 = isco08*10


**********************************************
* testing 
**********************************************
crosswalk micro = mc.isco08_3_to_micro(isco08 case.mcempstat(selfemp nsuperv))

* Valid missings. these are too broad 
count if missing(micro)
table isco08 selfemp nsuperv if missing(micro)
levelsof isco08 if missing(micro)

crosswalk micro4 = mc.isco08_3_to_micro(isco08_4 case.mcempstat(selfemp nsuperv))
* this doesnt code anything except the armed forces, expected. Its trying to match 3 digit codes. 
count if missing(micro4)

drop micro4
crosswalk micro4 = mc.isco08_to_micro(isco08_4 case.mcempstat(selfemp nsuperv))
* Valid missings. these are too broad 
count if missing(micro)
table isco08 selfemp nsuperv if missing(micro)
levelsof isco08 if missing(micro)


* testing supvis = -1
replace nsuperv= -1
drop micro
crosswalk micro = mc.isco08_3_to_micro(isco08 case.mcempstat(selfemp nsuperv))
* Valid missings. these are too broad 
count if missing(micro)
* pass if all missing 



* testing supvis = missing
replace nsuperv= .
drop micro
crosswalk micro = mc.isco08_3_to_micro(isco08 case.mcempstat(selfemp nsuperv))
* Valid missings. these are too broad 
count if missing(micro)
* pass if all missing 


* testing selfemp = missing
bysort isco08: replace nsuperv=  (_n == 3)
replace selfemp= .
drop micro
crosswalk micro = mc.isco08_3_to_micro(isco08 case.mcempstat(selfemp nsuperv))
* Valid missings. these are too broad 
count if missing(micro)
* pass if all missing 





