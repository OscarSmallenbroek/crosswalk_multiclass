{smcl}
{* version 1.0.1  18aug2026}{...}
{hi:case.mcempstat()} {hline 2} Multilevel Socio-Economic Classes employment status case function

{title:Syntax}

        {cmd:case.mcempstat(}{help varname:{it:sempl}} [{help varname:{it:supvis}}]{cmd:)}

    {it:sempl}!=0 indicates that a respondent is self-employed
    if {it:sempl}==0: {it:supvis}>0 indicates that a respondent has supervisory status
    if {it:sempl}!=0: {it:supvis} specifies the number of employees

{title:Description}

{pstd}
    {helpb crosswalk} case function for use with the Multilevel Socio-Economic Classes translation
    tables. The function distinguishes the following cases:

        1 = employment status unknown ({it:sempl} is missing)
        2 = employed, without supervisory status
        3 = employed, with supervisory status
        4 = self-employed, no employees
        5 = self-employed, 1-9 employees
        6 = self-employed, 10 or more employees

{pstd}
    This is the same case coding as
    {helpb _cwcasefcn_esec88:case.esec88()}, so either function can be used
    with the {cmd:mc.} tables.

{pstd}
    Employees with supervisory status are employees who have formal
    responsibility for supervising the work of other employees. If the data
    does not contain a direct measure of supervisory status, Harrison and Rose
    (2006, section 4.7) suggest coding employees as supervisors if they are
    supervising at least three people.

{pstd}
    Missing or negative values in {it:supvis} are treated as {it:supvis}=0. If
    {it:supvis} is not specified it is assumed to be 0 throughout, which
    collapses the self-employed into case 4 and employees into case 2.

{pstd}
    Unlike ESeC, the Multilevel Socio-Economic Classes schemes have no simplified variant for unknown
    employment status: column 1 of every {cmd:mc.} table is {cmd:.}, so
    observations with missing {it:sempl} come back uncoded.

{title:Examples}

{phang2}{cmd:. crosswalk micro = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))}{p_end}
{phang2}{cmd:. crosswalk macro = mc.isco88com_to_macro(isco88 case.mcempstat(selfemp nsuperv))}{p_end}

{title:References}

{phang}
    Harrison, E., D. Rose. 2006. The European Socio-economic Classification
    (ESeC) User Guide. Institute for Social and Economic Research, University
    of Essex. Available from
    {browse "http://www.iser.essex.ac.uk/archives/esec/user-guide"}.
    {p_end}
{hline}
{asis}
// parse input
gettoken case   0 : 0
gettoken touse  0 : 0
gettoken sempl  0 : 0
gettoken supvis 0 : 0
if `"`0'"'!="" error 198
unab sempl: `sempl', min(1) max(1)
if `"`supvis'"'!="" {
    unab supvis: `supvis', min(1) max(1)
    count if `supvis'>=. & `sempl'<. & `touse'
    if r(N) noi di as txt "({cmd:`supvis'}: missing values treated as 0)"
    count if `supvis'<0 & `sempl'<. & `touse'
    if r(N) noi di as txt "({cmd:`supvis'}: negative values treated as 0)"
}
else noi di as txt "({it:supvis} not specified; assumed 0)"
// generate cases
replace `case' = 1 if `touse'
replace `case' = 2 if `sempl'==0 & `touse'
replace `case' = 4 if `sempl'!=0 & `sempl'<. & `touse'
if "`supvis'"!="" {
    replace `case' = 3 if `supvis'>=1  & `supvis'<.  & `case'==2 & `touse'
    replace `case' = 5 if `supvis'>=1  & `supvis'<10 & `case'==4 & `touse'
    replace `case' = 6 if `supvis'>=10 & `supvis'<.  & `case'==4 & `touse'
}
