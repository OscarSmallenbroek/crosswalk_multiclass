"""Shared reference blocks for the help files of both packages.

Kept in one place so the standalone package, the add-on tables and the two
master help files cannot drift apart.
"""

AUTHOR = "Oscar Smallenbroek"

# The two papers behind the schemes in this package.
REF_HERTEL_2025 = """{phang}
    Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
    Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
    Approaches to Class Analysis. European Societies 1-65.
    doi:10.1162/euso_a_00044.
    {p_end}"""

REF_SMALLENBROEK_2022 = """{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class
    Hierarchies in Postindustrial Societies: A Criterion and Construct
    Validation of EGP and ESEC Across 31 Countries. Sociological Methods &
    Research 53(3):1412-52. doi:10.1177/00491241221134522.
    {p_end}"""

REF_HARRISON_ROSE = """{phang}
    Harrison, E., D. Rose. 2006. The European Socio-economic Classification
    (ESeC) User Guide. Institute for Social and Economic Research, University
    of Essex.
    {p_end}"""

REF_JANN = """{phang}
    Jann, B. 2025. crosswalk: Stata module to recode variables based on
    crosswalk tables. Statistical Software Components S459534, Boston College
    Department of Economics.
    {p_end}"""

# Micro-class scheme lineage.
REF_MICROCLASS = """{phang}
    Smallenbroek, O., F. R. Hertel, C. Barone. n.d. Adapting the Microclass
    Schema for Cross-national Research. Retrieved
    {browse "https://osf.io/preprints/socarxiv/xaqju_v1":osf.io/preprints/socarxiv/xaqju_v1}.
    {p_end}"""

REF_JONSSON_2009 = """{phang}
    Jonsson, J. O., D. B. Grusky, M. Di Carlo, R. Pollak, M. C. Brinton. 2009.
    Microclass Mobility: Social Reproduction in Four Countries. American
    Journal of Sociology 114(4):977-1036. doi:10.1086/596566.
    {p_end}"""

REF_WEEDEN_2005 = """{phang}
    Weeden, K. A., D. B. Grusky. 2005. The Case for a New Class Map. American
    Journal of Sociology 111(1):141-212. doi:10.1086/428815.
    {p_end}"""

REF_GRUSKY_2000 = """{phang}
    Grusky, D. B., K. A. Weeden, J. B. Sorensen. 2000. The Case for Realism in
    Class Analysis. Political Power and Social Theory 14:291-305.
    {p_end}"""

# Which paper covers what. The Micro-SEC caveat matters: the version assessed in
# Hertel et al. (2025) is an earlier prototype, not what this package ships.
PROVENANCE_NOTE = """{pstd}
    Smallenbroek, Hertel and Barone (2022) introduced Macro-SEC. Hertel, Barone
    and Smallenbroek (2025) assessed Macro-SEC and Micro-SEC alongside other class
    schemes.

{pstd}
    Note that the Micro-SEC assessed in Hertel et al. (2025) is an earlier
    prototype, whose development is documented at
    {browse "https://osf.io/preprints/socarxiv/962q3_v1"}. It is {it:not} the
    version of Micro-SEC shipped here. The paper documenting the version
    implemented in this package is under review."""

MICROCLASS_NOTE = """{pstd}
    The micro-class scheme is a separate 77-category schema built from ISCO-08
    occupational titles and descriptions, following the micro-class approach of
    Grusky, Weeden and Sorensen (2000) and Weeden and Grusky (2005) and
    emulating the categories of Jonsson et al. (2009). It is documented in
    Smallenbroek, Hertel and Barone (n.d.). It is not the same thing as the
    30-class Micro-SEC scheme, which this package calls {cmd:micro}."""

# ISCO-88 vs ISCO-88(COM): the source data behind every isco88com-origin table
# in this package (micro, meso, esec, macro) is keyed on ISCO-88(COM), the EU
# variant, not raw ISCO-88. crosswalk documents the same caveat for its own
# isco88_to_esec() in the Source section of _cwfcn_isco88_3_to_esec.sthlp;
# these two notes follow that wording so both packages read consistently.
ISCO88COM_NOTE_ADDON = """{pstd}
    Note that this table is based on
    {browse "https://warwick.ac.uk/fac/soc/ier/research/classification/isco88":ISCO-88(COM)},
    the European Union variant of the ISCO-88. If your data contains ISCO-88
    codes you might first want to translate these codes to ISCO-88(COM) using
    {helpb _cwfcn_isco88_to_isco88com:isco88_to_isco88com()}."""

ISCO88COM_NOTE_STANDALONE = """{pstd}
    Note that this table is based on
    {browse "https://warwick.ac.uk/fac/soc/ier/research/classification/isco88":ISCO-88(COM)},
    the European Union variant of the ISCO-88. If your data contains ISCO-88
    codes rather than ISCO-88(COM) you might first want to translate them,
    for instance using {cmd:isco88_to_isco88com()} from the
    {browse "https://github.com/benjann/crosswalk":crosswalk} package."""

# Pointer for the Source section of the macro tables. crosswalk already
# provides isco88_to_esec() and isco08_to_esec(), so this package does not
# duplicate them; note the case functions differ from the ones used here. The
# full explanation lives in the master help file, crosswalk_multiclass.sthlp.
ESEC_POINTER_SHORT = """{pstd}
    For plain 9-class ESeC, use {helpb crosswalk}'s own
    {helpb _cwfcn_isco88_to_esec:isco88_to_esec()} /
    {helpb _cwfcn_isco08_to_esec:isco08_to_esec()} rather than a table from
    this package; see {help crosswalk_multiclass##esec:crosswalk_multiclass}
    for why, and note that they take a different case function
    ({helpb _cwcasefcn_esec88:case.esec88()} /
    {helpb _cwcasefcn_esec:case.esec()}, not
    {helpb _cwcasefcn_mcempstat:case.mcempstat()})."""


def refs(*blocks):
    """Assemble a {title:References} section from the blocks above."""
    return "{title:References}\n\n" + "\n\n".join(blocks) + "\n"


# --- ASCII hygiene -----------------------------------------------------
# SSC materials must be plain ASCII. Source value labels occasionally carry
# typographic punctuation (e.g. the curly apostrophe in "teachers' aides").
_ASCII_MAP = {
    "‘": "'", "’": "'", "‚": "'", "‛": "'",
    "“": "'", "”": "'", "„": "'",
    "–": "-", "—": "-", "−": "-",
    "…": "...", " ": " ", "­": "",
    "ʼ": "'", "´": "'",
}


def to_ascii(s):
    """Fold typographic punctuation to ASCII."""
    for k, v in _ASCII_MAP.items():
        s = s.replace(k, v)
    return s


def assert_ascii(s, what):
    bad = sorted({c for c in s if ord(c) > 126})
    if bad:
        raise AssertionError("%s contains non-ASCII: %s"
                             % (what, [hex(ord(c)) for c in bad]))
    return s
