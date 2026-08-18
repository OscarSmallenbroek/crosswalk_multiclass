{smcl}
{* version 1.0.0  18aug2026}{...}
{hi:case.mcstatus5()} {hline 2} Case function for the MultiClass 1-5 status coding

{title:Syntax}

        {cmd:case.mcstatus5(}{help varname:{it:empstat}}{cmd:)}

    where {it:empstat} is coded

        1 = self-employed with 10 or more employees (large employer)
        2 = self-employed with 1-9 employees (small employer)
        3 = self-employed without employees
        4 = employee with supervisory status
        5 = employee without supervisory status

{title:Description}

{pstd}
    {helpb crosswalk} case function for data that already carries employment
    status on the 1-5 scale used by the MultiClass source crosswalk files.
    It maps that scale onto the case numbering of the {cmd:mc.} tables:

        {it:empstat} 5  ->  case 2   employed, without supervisory status
        {it:empstat} 4  ->  case 3   employed, with supervisory status
        {it:empstat} 3  ->  case 4   self-employed, no employees
        {it:empstat} 2  ->  case 5   self-employed, 1-9 employees
        {it:empstat} 1  ->  case 6   self-employed, 10 or more employees

{pstd}
    Values of {it:empstat} that are missing or outside 1-5 are mapped to case
    1 (employment status unknown), which is coded {cmd:.} in every {cmd:mc.}
    table and therefore comes back uncoded.

{pstd}
    This function exists because the two numbering schemes run in opposite
    directions. Passing a 1-5 status variable directly as the {it:case} would
    silently select the wrong columns, so route it through this function
    instead.

{pstd}
    To build the case from a self-employment indicator and a supervisory or
    employee-count variable, use
    {helpb _cwcasefcn_mcempstat:case.mcempstat()}.

{title:Examples}

{phang2}{cmd:. crosswalk micro = mc.isco08_to_micro(isco08 case.mcstatus5(empstat))}{p_end}
{phang2}{cmd:. crosswalk meso = mc.isco88com_to_meso(isco88 case.mcstatus5(empstat))}{p_end}

{title:Also see}

{psee}
    {helpb crosswalk_multiclass} {hline 2} overview of the {cmd:mc.} tables
{p_end}
{psee}
    {helpb _cwcasefcn_mcempstat:case.mcempstat()} {hline 2} build the case from
    a self-employment indicator and a supervisory variable instead
{p_end}
{hline}
{asis}
// parse input
gettoken case    0 : 0
gettoken touse   0 : 0
gettoken empstat 0 : 0
if `"`0'"'!="" error 198
unab empstat: `empstat', min(1) max(1)
count if !inlist(`empstat',1,2,3,4,5) & `touse'
if r(N) noi di as txt "({cmd:`empstat'}: " r(N) /*
    */ " observation(s) not in 1-5; treated as unknown employment status)"
// generate cases: case = 7 - empstat, everything else unknown
replace `case' = 1 if `touse'
replace `case' = 7 - `empstat' if inlist(`empstat',1,2,3,4,5) & `touse'
