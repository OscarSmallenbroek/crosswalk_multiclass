{smcl}
{* version 1.0.3  18aug2026}{...}
{vieweralsosee "crosswalk" "help crosswalk"}{...}
{viewerjumpto "Description" "crosswalk_multiclass##description"}{...}
{viewerjumpto "Syntax" "crosswalk_multiclass##syntax"}{...}
{viewerjumpto "Employment status" "crosswalk_multiclass##case"}{...}
{viewerjumpto "Tables" "crosswalk_multiclass##tables"}{...}
{viewerjumpto "Class schemes" "crosswalk_multiclass##schemes"}{...}
{viewerjumpto "Where is ESeC?" "crosswalk_multiclass##esec"}{...}
{viewerjumpto "Examples" "crosswalk_multiclass##examples"}{...}
{viewerjumpto "Sources" "crosswalk_multiclass##sources"}{...}
{viewerjumpto "References" "crosswalk_multiclass##refs"}{...}
{hi:crosswalk_multiclass} {hline 2} MultiClass crosswalk tables for ISCO-88com and ISCO-08


{marker description}{title:Description}

{pstd}
    {cmd:crosswalk_multiclass} is an add-on for {helpb crosswalk} (Jann 2025)
    providing crosswalk tables that translate ISCO-88com and ISCO-08
    occupational codes into class schemes of the MultiClass schema:
    {bf:MicroSEC} (30 classes), the {bf:meso-class} scheme (18 classes),
    {bf:ESeC-MP} (11 classes), and, for ISCO-08, a 77-category {bf:micro-class}
    scheme. It does {it:not} provide a plain 9-class ESeC table, because
    {helpb crosswalk} already ships one; see
    {help crosswalk_multiclass##esec:Where is ESeC?} below.

{pstd}
    The package contains no ado-file and defines no command of its own. All
    recoding is carried out by {helpb crosswalk}, which must be installed, as
    must {helpb mf_mm_version:moremata}.

{pstd}
    MicroSEC, the meso-class and ESeC-MP are defined jointly over occupation
    {it:and} employment relation: the same ISCO code is assigned to different
    classes depending on whether the respondent is an employee, a supervisor,
    or self-employed with or without employees. The employment relation is
    supplied through a {help crosswalk##case:case} argument, for which two case
    functions are provided. The micro-class scheme is purely occupational and
    takes no case argument.


{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:crosswalk} {it:newvar} {cmd:=} {cmd:mc.}{it:origin}{cmd:_to_}{it:scheme}{cmd:(}{it:iscovar} {it:case}{cmd:)} {ifin}
[{cmd:,} {it:{help crosswalk##opt:options}}]

{pstd}
    where {it:origin} is {cmd:isco88com} or {cmd:isco08} for 4-digit codes, or
    {cmd:isco88_3} or {cmd:isco08_3} for 3-digit minor groups; {it:scheme} is
    {cmd:micro}, {cmd:meso}, {cmd:esecmp} or (ISCO-08 only) {cmd:microclass};
    and {it:case}, which {cmd:microclass} does not take, is normally one of

{p 8 17 2}
{helpb _cwcasefcn_mcempstat:case.mcempstat(}{it:sempl} [{it:supvis}]{cmd:)}

{p 8 17 2}
{helpb _cwcasefcn_mcstatus5:case.mcstatus5(}{it:empstat}{cmd:)}

{pstd}
    Type the tables with the {cmd:mc.} prefix, as shown. The prefix is what
    makes {helpb crosswalk} pick up this package's class labels rather than
    any same-named label set from {helpb crosswalk} itself or another add-on;
    see {help crosswalk##pfx:prefix syntax}.


{marker case}{title:Employment status}

{pstd}
    The destination columns follow the same convention as the ESeC tables that
    ship with {helpb crosswalk}:

        1 = employment status unknown
        2 = employed, without supervisory status
        3 = employed, with supervisory status
        4 = self-employed, no employees
        5 = self-employed, 1-9 employees
        6 = self-employed, 10 or more employees

{pstd}
    {bf:Column 1 is} {cmd:.} {bf:in every table.} The MultiClass schemes have
    no simplified variant for unknown employment status. {helpb crosswalk}
    sends every observation whose {it:case} is missing or out of range to
    column 1, so coding column 1 as missing is what makes those observations
    come back uncoded rather than silently picking up another class.

{pstd}
    {bf:Do not pass a bare 1-5 status variable as the} {it:case}. The numbering
    above runs in the opposite direction to the 1-5 employment status scale
    used by the source crosswalks, so a bare variable would select the wrong
    columns without any error being issued. Route such a variable through
    {helpb _cwcasefcn_mcstatus5:case.mcstatus5()}.

{pstd}
    Because the numbering matches the {helpb crosswalk} ESeC convention
    exactly, {helpb _cwcasefcn_esec88:case.esec88()} may also be used with
    these tables and gives identical results to
    {helpb _cwcasefcn_mcempstat:case.mcempstat()}.


{marker schemes}{title:Class schemes}

{pstd}
    {cmd:micro} {hline 1} micro-class scheme, 30 classes, values 10-111. See
    {helpb _cwfcn_labels_mc_micro:labels_mc_micro()}.

{pstd}
    {cmd:meso} {hline 1} meso-class scheme, 18 classes, values 14-49. See
    {helpb _cwfcn_labels_mc_meso:labels_mc_meso()}.

{pstd}
    {cmd:esecmp} {hline 1} ESeC multi-purpose variant, 11 classes. See
    {helpb _cwfcn_labels_mc_esecmp:labels_mc_esecmp()}.

{pstd}
    {cmd:microclass} {hline 1} micro-class scheme, 77 categories, ISCO-08 only.
    Purely occupational, so it takes no {it:case} argument and stands outside
    the nesting below. See
    {helpb _cwfcn_labels_mc_microclass:labels_mc_microclass()}.

{pstd}
    The micro-class scheme is a separate 77-category schema built from ISCO-08
    occupational titles and descriptions, following the micro-class approach of
    Grusky, Weeden and Sorensen (2000) and Weeden and Grusky (2005) and
    emulating the categories of Jonsson et al. (2009). It is documented in
    Smallenbroek, Hertel and Barone (n.d.). It is not the same thing as the
    30-class MicroSEC scheme, which this package calls {cmd:micro}.

{pstd}
    The employment-relation schemes nest: MicroSEC, the meso-class and ESeC-MP
    each determine the ESeC class on their own. 30 MicroSEC classes aggregate
    to 18 meso-classes and then to 9 ESeC classes, and the 11 ESeC-MP classes
    collapse to the same 9 ESeC classes (see
    {help crosswalk_multiclass##esec:Where is ESeC?} for that collapse and for
    why plain ESeC itself is not shipped here). The 77-category micro-class
    scheme is not part of that hierarchy.


{marker esec}{title:Where is ESeC?}

{pstd}
    This package does not provide an {cmd:mc.}{it:origin}{cmd:_to_esec()}
    table. {helpb crosswalk} already ships
    {helpb _cwfcn_isco88_to_esec:isco88_to_esec()} and
    {helpb _cwfcn_isco08_to_esec:isco08_to_esec()} for plain 9-class ESeC, so
    duplicating them here would only risk the two falling out of step. Use
    those directly.

{pstd}
    Their {it:case} argument is {it:not} one of
    {helpb _cwcasefcn_mcempstat:case.mcempstat()} or
    {helpb _cwcasefcn_mcstatus5:case.mcstatus5()}: {cmd:isco88_to_esec()} takes
    {helpb _cwcasefcn_esec88:case.esec88()} (6 columns, with an "unknown" case,
    the same numbering used throughout this add-on), while
    {cmd:isco08_to_esec()} takes {helpb _cwcasefcn_esec:case.esec()} (5
    columns, {it:no} "unknown" case). Passing the wrong case function will not
    raise an error; it will silently select the wrong columns.

{pstd}
    {cmd:mc.}{it:origin}{cmd:_to_esecmp()} remains available here and collapses
    to ESeC classes with the rule {c -(}1,2{c )-}->1, {c -(}3,4{c )-}->2, 5->3,
    6->4, 7->5, 8->6, 9->7, 10->8, 11->9. That collapse and
    {helpb crosswalk}'s own {cmd:isco88_to_esec()}/{cmd:isco08_to_esec()} are
    {it:independently sourced}: ours from the MicroSEC crosswalk files, theirs
    from the Harrison/Rose ESeC matrix. Checked against every 4-digit code
    either source recognises:

{pstd}
        ISCO-08:      0 disagreements on 2,930 comparable cells
        ISCO-88(COM): 0 disagreements on 2,531 comparable cells

{pstd}
    ("Comparable" excludes cells where only one source has a row at all;
    such coverage gaps run in both directions and are not disagreements.)
    ISCO-08 needed no adjustment to reach that. For ISCO-88(COM) the
    MicroSEC-derived collapse originally disagreed with
    {cmd:isco88_to_esec()} on 8 cells, all confined to two well-known ESeC
    edge cases -- minor group 011 (Commissioned armed forces officers) and
    621 (Subsistence agricultural and fishery workers), where the ESeC
    employment-relation categories do not apply cleanly to the occupation.
    Those two minor groups are therefore hand-set to {helpb crosswalk}'s own
    native values rather than derived.

{pstd}
    The override covers the micro-class and meso-class as well as ESeC-MP,
    so that the three schemes still {help crosswalk_multiclass##schemes:nest}:
    011 becomes Armed forces, except in the supervisory column where it
    becomes Lower managers, and 621 becomes primary production self-employed
    throughout. Each replacement is the class that already corresponds to the
    ESeC-MP class being set, so no new micro-class to meso-class pairing was
    introduced. These are the only hand-set values in the package.


{marker tables}{title:Tables}

{pstd}
    4-digit ISCO, implemented as wrappers that first apply the relevant
    {helpb crosswalk} 4-digit to 3-digit collapse:

{p2colset 9 44 46 2}{...}
{p2col :{helpb _cwfcn_mc_isco88com_to_micro:mc.isco88com_to_micro()}}ISCO-88com to micro-class{p_end}
{p2col :{helpb _cwfcn_mc_isco88com_to_meso:mc.isco88com_to_meso()}}ISCO-88com to meso-class{p_end}
{p2col :{helpb _cwfcn_mc_isco88com_to_esecmp:mc.isco88com_to_esecmp()}}ISCO-88com to ESeC-MP{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_micro:mc.isco08_to_micro()}}ISCO-08 to micro-class{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_meso:mc.isco08_to_meso()}}ISCO-08 to meso-class{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_esecmp:mc.isco08_to_esecmp()}}ISCO-08 to ESeC-MP{p_end}
{p2col :{helpb _cwfcn_mc_isco08_to_microclass:mc.isco08_to_microclass()}}ISCO-08 to micro-class (no case){p_end}
{p2colreset}{...}

{pstd}
    3-digit ISCO minor groups, usable directly:

{p2colset 9 44 46 2}{...}
{p2col :{helpb _cwfcn_mc_isco88_3_to_micro:mc.isco88_3_to_micro()}}and {cmd:_to_meso()}, {cmd:_to_esecmp()}{p_end}
{p2col :{helpb _cwfcn_mc_isco08_3_to_micro:mc.isco08_3_to_micro()}}and {cmd:_to_meso()}, {cmd:_to_esecmp()}{p_end}
{p2colreset}{...}

{pstd}
    Case functions:

{p2colset 9 44 46 2}{...}
{p2col :{helpb _cwcasefcn_mcempstat:case.mcempstat()}}case from {it:sempl} and {it:supvis}{p_end}
{p2col :{helpb _cwcasefcn_mcstatus5:case.mcstatus5()}}case from a 1-5 status variable{p_end}
{p2colreset}{...}

{pstd}
    For plain ESeC, use {helpb crosswalk}'s own
    {helpb _cwfcn_isco88_to_esec:isco88_to_esec()} and
    {helpb _cwfcn_isco08_to_esec:isco08_to_esec()}; see
    {help crosswalk_multiclass##esec:Where is ESeC?} above.


{marker examples}{title:Examples}

{pstd}From a self-employment indicator and a supervisory variable:{p_end}
{phang2}{cmd:. crosswalk micro = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))}{p_end}

{pstd}From a status variable already coded 1-5:{p_end}
{phang2}{cmd:. crosswalk esecmp = mc.isco88com_to_esecmp(isco88 case.mcstatus5(empstat))}{p_end}

{pstd}All three employment-relation schemes at once:{p_end}
{phang2}{cmd:. foreach s in micro meso esecmp {c -(}}{p_end}
{phang2}{cmd:.     crosswalk `s' = mc.isco08_to_`s'(isco08 case.mcempstat(selfemp nsuperv))}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}Plain ESeC, via crosswalk's own table rather than this add-on:{p_end}
{phang2}{cmd:. crosswalk esec = isco08_to_esec(isco08 case.esec(selfemp nsuperv))}{p_end}

{pstd}3-digit data, without the 4-digit wrapper:{p_end}
{phang2}{cmd:. crosswalk meso = mc.isco08_3_to_meso(isco3 case.mcstatus5(empstat))}{p_end}

{pstd}The micro-class scheme takes no case argument:{p_end}
{phang2}{cmd:. crosswalk microclass = mc.isco08_to_microclass(isco08)}{p_end}


{marker sources}{title:Sources}

{pstd}
    The class values come from two source crosswalk files, covering ISCO-88com
    to micro-class and native ESeC, and ISCO-08 to micro-class, meso-class and
    ESeC-MP. Where the tables shipped here are not present in one of the two
    files they are derived: the meso-class from the micro-class, and ESeC-MP
    from micro-class and employment status. Native values always take
    precedence over derived ones. Each table's {cmd:Source} section records
    which route it took. The native ESeC values in the ISCO-88com file were
    used only to verify that the ESeC-MP collapse is correct (see
    {help crosswalk_multiclass##esec:Where is ESeC?}); they are not shipped as
    a table here.

{pstd}
    Two ISCO-88com cells did not aggregate to their own native ESeC class and
    were reassigned to the micro-class already used by the other employment
    statuses of the same ISCO code: 2400 self-employed to Business operation
    professionals (meso 21, ESeC 1), and 7300 employees to Technical
    supervisors (meso 46, ESeC 6).


{pstd}
    Smallenbroek, Hertel and Barone (2022) introduced ESeC-MP. Hertel, Barone
    and Smallenbroek (2025) assessed ESeC-MP and MicroSEC alongside other class
    schemes.

{pstd}
    Note that the MicroSEC assessed in Hertel et al. (2025) is an earlier
    prototype, whose development is documented at
    {browse "https://osf.io/preprints/socarxiv/962q3_v1"}. It is {it:not} the
    version of MicroSEC shipped here. The paper documenting the version
    implemented in this package is under review.


{title:Also see}

{psee}
    Online: {helpb crosswalk}, {helpb _cwcasefcn_mcempstat:case.mcempstat()},
    {helpb _cwcasefcn_mcstatus5:case.mcstatus5()}
{p_end}


{marker refs}{title:References}

{phang}
    Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
    Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
    Approaches to Class Analysis. European Societies 1-65.
    doi:10.1162/euso_a_00044.
    {p_end}

{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class
    Hierarchies in Postindustrial Societies: A Criterion and Construct
    Validation of EGP and ESEC Across 31 Countries. Sociological Methods &
    Research 53(3):1412-52. doi:10.1177/00491241221134522.
    {p_end}

{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. n.d. Adapting the Microclass
    Schema for Cross-national Research. Retrieved
    {browse "https://osf.io/preprints/socarxiv/xaqju_v1":osf.io/preprints/socarxiv/xaqju_v1}.
    {p_end}

{phang}
    Jonsson, J. O., D. B. Grusky, M. Di Carlo, R. Pollak, M. C. Brinton. 2009.
    Microclass Mobility: Social Reproduction in Four Countries. American
    Journal of Sociology 114(4):977-1036. doi:10.1086/596566.
    {p_end}

{phang}
    Weeden, K. A., D. B. Grusky. 2005. The Case for a New Class Map. American
    Journal of Sociology 111(1):141-212. doi:10.1086/428815.
    {p_end}

{phang}
    Grusky, D. B., K. A. Weeden, J. B. Sorensen. 2000. The Case for Realism in
    Class Analysis. Political Power and Social Theory 14:291-305.
    {p_end}

{phang}
    Harrison, E., D. Rose. 2006. The European Socio-economic Classification
    (ESeC) User Guide. Institute for Social and Economic Research, University
    of Essex.
    {p_end}

{phang}
    Jann, B. 2025. crosswalk: Stata module to recode variables based on
    crosswalk tables. Statistical Software Components S459534, Boston College
    Department of Economics.
    {p_end}


{title:Author}

{pstd}
Oscar Smallenbroek
{p_end}
