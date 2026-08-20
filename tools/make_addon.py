"""Generate the crosswalk add-on (multiclass-addon/) from the tables in build/,
as written by tools/make_tables.do. Run from D:/work/multiclass-package.

Help-file text here is USER-facing: how to call the table, what the cases mean,
which papers to cite. Derivation details, provenance and build mechanics belong
in dev/DEVELOPMENT.md, not in shipped .sthlp files."""

import io
import os

from citations import assert_ascii, to_ascii
from citations import (ESEC_POINTER_SHORT,
                       ISCO88COM_NOTE_ADDON, MICROCLASS_NOTE,
                       REF_MICROCLASS, REF_GRUSKY_2000,
                       REF_HARRISON_ROSE, REF_HERTEL_2025, REF_JANN,
                       REF_JONSSON_2009, REF_SMALLENBROEK_2022,
                       REF_WEEDEN_2005, refs)

BUILD = "build"
OUT = "multiclass-addon"

# esec is kept here so read_resolved() can still find its CSV column, but it is
# NOT shipped as an mc.<origin>_to_esec() table: crosswalk already provides
# isco88_to_esec() and isco08_to_esec(), and duplicating them here would risk
# the two falling out of step. See SHIPPED_SCHEMES and ESEC_POINTER_SHORT.
SCHEMES = {
    "micro":  ("Micro-SEC", 30, "Multilevel Socio-Economic Classes: Micro-SEC (30 classes)"),
    "meso":   ("Meso-SEC",  18, "Multilevel Socio-Economic Classes: Meso-SEC (18 classes)"),
    "esec":   ("ESeC",         9, "European Socio-economic Classification (9 classes)"),
    "macro": ("Macro-SEC",     11, "Macro-SEC - ESEC plus differentiation of SC I and II (11 classes)"),
}

# schemes actually generated as mc.<origin>_to_<scheme>() tables
SHIPPED_SCHEMES = {k: v for k, v in SCHEMES.items() if k != "esec"}

# The only hand-set values in the package, ISCO-88 only. Two minor groups where
# our Micro-SEC-derived Macro-SEC collapse disagreed with crosswalk's own native
# isco88_to_esec() (the Harrison/Rose matrix), both classic edge cases where the
# ESeC employment-relation categories don't map cleanly onto the occupation:
#
#   011 Commissioned armed forces officers      native ESeC case1-6 = 3,3,2,3,3,3
#   621 Subsistence agricultural and fishery    native ESeC = 5 throughout
#
# The override MUST cover micro and meso too, not just macro: all three schemes
# are advertised to nest, and moving only macro left micro and meso aggregating
# to a different ESeC class here (10 and 8 violations). Each replacement is the
# class already corresponding to the macro class being set, and every
# micro -> meso pairing is the one the deterministic 30 -> 18 map already uses:
#
#   macro 5 "Higher-grade White-collar"  <- micro 52 "Armed forces"      -> meso 23
#   macro 3 "Lower Manager"              <- micro 30 "Lower managers"    -> meso 22
#   macro 7 "Self-employed and Small
#             Employer agriculture"       <- micro 70 "Primary production
#                                              self-employed workers"    -> meso 15
#
# Each value list holds exactly 5 entries for case2..case6 (employed w/o super,
# employed w/ super, self no employees, self 1-9, self 10+); case1 (unknown) is
# never set here and is always "." like every other row.
#
# Full rationale, including the one genuine judgement call (011's supervisory
# column), is in dev/DEVELOPMENT.md. This is deliberately NOT documented in the
# shipped help files -- users never see the underlying tables.
MACRO_ESEC_OVERRIDE = {
    "011": ["5", "3", "5", "5", "5"],  # ESeC 3,2,3,3,3 (case2-6) -> macro
    "621": ["7", "7", "7", "7", "7"],  # ESeC 5,5,5,5,5 (case2-6) -> macro
}

MICRO_ESEC_OVERRIDE = {
    "011": ["52", "30", "52", "52", "52"],
    "621": ["70", "70", "70", "70", "70"],
}

MESO_ESEC_OVERRIDE = {
    "011": ["23", "22", "23", "23", "23"],
    "621": ["15", "15", "15", "15", "15"],
}

# scheme -> the override table to apply to the ISCO-88 3-digit tables
OVERRIDE = {
    "macro": MACRO_ESEC_OVERRIDE,
    "micro":  MICRO_ESEC_OVERRIDE,
    "meso":   MESO_ESEC_OVERRIDE,
}

# origin key -> (source file stem, key transform, crosswalk 4->3 fcn, nice name,
#                wrapper origin name)
SOURCES = {
    "isco88": ("isco88com", lambda k: "%03d" % (int(k) // 10),
               "isco88_to_isco88_3", "ISCO-88(com)", "isco88com"),
    "isco08": ("isco08", lambda k: "%03d" % (int(k) // 10),
               "isco08_to_isco08_3", "ISCO-08", "isco08"),
}

CASEDOC = """{pstd}
    Cases (destination columns), following the same convention as the ESeC
    tables shipped with {helpb crosswalk}:

        1 = employment status unknown
        2 = employed, without supervisory status
        3 = employed, with supervisory status
        4 = self-employed, no employees
        5 = self-employed, 1-9 employees
        6 = self-employed, 10 or more employees

{pstd}
    Column 1 is {cmd:.} throughout: the Multilevel Socio-Economic Classes have no simplified
    variant for unknown employment status, so observations whose employment
    status is unknown come back uncoded rather than picking up another class.
"""

REFS = refs(REF_HERTEL_2025, REF_SMALLENBROEK_2022,
            REF_HARRISON_ROSE, REF_JANN)

REFS_MICROCLASS = refs(REF_MICROCLASS, REF_JONSSON_2009,
                       REF_WEEDEN_2005, REF_GRUSKY_2000, REF_JANN)

# Class label text. These are the curated versions of the value labels carried
# by the source .dta files: double spaces collapsed, and the source typo
# "Techincal workers" corrected. They live here rather than being re-read from
# the .dta on every build so that the corrections are not silently lost.
# microclass is not listed: its 77 labels come from build/labels_microclass.txt,
# written by tools/make_tables.do from the authoritative micro08 value label.
LABELS = {
    "micro": [
        (10, "Higher managers"),
        (11, "Large entrepreneurs"),
        (20, "Business operation professionals"),
        (21, "Health professionals"),
        (22, "Science and ICT professionals"),
        (23, "Social and teaching professionals"),
        (30, "Lower managers"),
        (40, "Administrative associate professionals"),
        (41, "Health associate professionals"),
        (42, "Cultural associate professionals"),
        (43, "Technical associate professionals"),
        (44, "Teaching associate professionals"),
        (50, "General clerks"),
        (51, "Legal and social associate professionals"),
        (52, "Armed forces"),
        (60, "Self-employed trade, craft and service workers"),
        (61, "Self-employed white-collar workers"),
        (62, "Small entrepreneurs"),
        (70, "Primary production self-employed workers"),
        (80, "Technical supervisors"),
        (81, "Interpersonal service supervisors"),
        (82, "White-collar supervisors"),
        (91, "Personal care workers"),
        (92, "Interpersonal service workers"),
        (93, "Sales workers"),
        (100, "Primary production workers"),
        (102, "Industrial workers"),
        (103, "Transport workers"),
        (110, "Routine industrial workers"),
        (111, "Routine service workers"),
    ],
    "meso": [
        (14, "Self-employed"),
        (15, "Self-employed agriculture"),
        (21, "Higher administrative managers and professionals"),
        (22, "Lower administrative managers and professionals"),
        (23, "Associate administrative professionals"),
        (26, "Administrative supervisors"),
        (27, "Administrative workers"),
        (31, "Higher interpersonal professionals"),
        (32, "Lower interpersonal professionals"),
        (33, "Associate interpersonal professionals"),
        (36, "Interpersonal supervisors"),
        (37, "Interpersonal workers"),
        (39, "Routine interpersonal workers"),
        (41, "Higher technical professionals"),
        (42, "Lower technical professionals"),
        (46, "Technical supervisors"),
        (48, "Technical workers"),
        (49, "Routine technical workers"),
    ],
    "macro": [
        (1, "Higher Manager"),
        (2, "Higher Professional"),
        (3, "Lower Manager"),
        (4, "Lower Professional"),
        (5, "Higher-grade White-collar"),
        (6, "Self-employed and Small Employer"),
        (7, "Self-employed and Small Employer agriculture"),
        (8, "Higher-grade Blue-collar"),
        (9, "Lower-grade White-collar"),
        (10, "Lower-grade Blue-collar"),
        (11, "Routine"),
    ],
}

# Source sections point at the papers, not at internal file and variable
# names: a user of the add-on never sees the underlying tables. The derivation
# details live in dev/DEVELOPMENT.md.
PROV = {
    "micro": ["    Multilevel Socio-Economic Classes crosswalk files for Micro-SEC,",
              "    the 30-class scheme assessed in Hertel, Barone and Smallenbroek",
              "    (2025); see References."],
    "meso":  ["    Multilevel Socio-Economic Classes crosswalk files for Meso-SEC,",
              "    the 18-class scheme assessed in Hertel, Barone and Smallenbroek",
              "    (2025); see References."],
    "macro": ["    Multilevel Socio-Economic Classes crosswalk files for Macro-SEC,",
              "    introduced in Smallenbroek, Hertel and Barone (2022); see",
              "    References."],
}


def read_src(stem, scheme):
    """Read a table block straight out of build/, as written by
    tools/make_tables.do from the source .dta files."""
    rows = []
    path = os.path.join(BUILD, "d_%s_to_%s.txt" % (stem, scheme))
    for line in io.open(path, encoding="utf-8"):
        t = line.split()
        if t:
            rows.append(t)
    return rows


def read_resolved(version):
    """Read build/addon3_<version>.csv: the standalone command's own answer for
    every 3-digit code, resolved through its minor -> sub-major -> major
    fallback. Returns {code3str: {scheme: [c1..c5]}}."""
    path = os.path.join("build", "addon3_%s.csv" % version)
    out = {}
    with io.open(path, encoding="utf-8") as fh:
        head = fh.readline().strip().split(",")
        idx = {name: head.index("mc_" + name) for name in SCHEMES}
        for line in fh:
            f = line.strip().split(",")
            if not f or not f[0]:
                continue
            code3 = "%03d" % int(f[0])
            cell = out.setdefault(code3, {s: [None] * 5 for s in SCHEMES})
            case = int(f[1])
            for name in SCHEMES:
                v = f[idx[name]].strip()
                cell[name][case - 1] = v if v else "."
    return out


def header(fnname, title):
    return ["{smcl}",
            "{* version 1.0.0  18aug2026}{...}",
            "{hi:%s()} {hline 2} %s" % (fnname, title),
            ""]


def write(path, lines):
    body = assert_ascii(to_ascii(chr(10).join(lines) + chr(10)), path)
    io.open(path, "w", encoding="ascii", newline=chr(10)).write(body)


def main():
    if not os.path.isdir(OUT):
        os.makedirs(OUT)
    made = []

    # remove any stale esec tables from a previous generation: crosswalk
    # already ships isco88_to_esec()/isco08_to_esec(), so this package does
    # not (any longer) duplicate them -- see SHIPPED_SCHEMES above.
    stale = ["_cwfcn_labels_mc_esec.sthlp"]
    for origin, (stem, keyfn, collapse, nicesrc, wrapname) in SOURCES.items():
        stale.append("_cwfcn_mc_%s_3_to_esec.sthlp" % origin)
        stale.append("_cwfcn_mc_%s_to_esec.sthlp" % wrapname)
    for f in stale:
        p = os.path.join(OUT, f)
        if os.path.exists(p):
            os.remove(p)
            print("removed stale %s" % p)

    # ---------------------------------------------------- 3-digit tables
    for origin, (stem, keyfn, collapse, nicesrc, _w) in SOURCES.items():
        resolved = read_resolved(origin)
        # keys that came straight from the source crosswalk file, as opposed to
        # rows filled in from the enclosing sub-major or major group
        native = set(keyfn(r[0]) for r in read_src(stem, "micro"))
        keys = sorted(resolved, key=int)
        n_fallback = len([k for k in keys if k not in native])
        for scheme, (sname, ncls, sdesc) in SHIPPED_SCHEMES.items():
            # resolved[k][scheme] is indexed by the multiclass 1-5 employment
            # status coding. crosswalk columns run 1 = unknown, then 2..6 in
            # the reverse order (employee first, large employer last), matching
            # the ESeC tables that ship with crosswalk.
            rows = [[k, "."] + [resolved[k][scheme][7 - j - 1] for j in range(2, 7)]
                    for k in keys]
            if origin == "isco88" and scheme in OVERRIDE:
                ov = OVERRIDE[scheme]
                present = set(r[0] for r in rows if r[0] in ov)
                assert present == set(ov), \
                    "expected minor groups 011 and 621 in the isco88 key list"
                rows = [[r[0], "."] + ov[r[0]] if r[0] in ov else r
                        for r in rows]
            fn = "mc_%s_3_to_%s" % (origin, scheme)
            L = header(fn, "Translate 3-digit %s to %s" % (nicesrc, sname))
            L += ["{title:Syntax}", "",
                  "        {cmd:mc.%s_3_to_%s(}{it:varname} {it:case}{cmd:)}"
                  % (origin, scheme),
                  "",
                  "{pstd}",
                  "    where {it:varname} contains 3-digit %s minor group codes"
                  % nicesrc,
                  "    and {it:case} selects the employment status column.",
                  "",
                  "{pstd}",
                  "    Typical usage:",
                  "",
                  "        {cmd:mc.%s_3_to_%s(}{it:varname} "
                  "{cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}"
                  % (origin, scheme),
                  "",
                  "{title:Description}", "",
                  "{pstd}",
                  "    {helpb crosswalk} table translating 3-digit %s minor" % nicesrc,
                  "    groups to the %s. The table also" % sdesc,
                  "    carries rows for sub-major (2-digit) and major (1-digit)",
                  "    groups, written as 3-digit codes padded with zeros on the",
                  "    right, so that partially coded observations still match.",
                  "",
                  CASEDOC,
                  "{pstd}",
                  "    Cells that the source tables leave unclassified are coded",
                  "    {cmd:.} and produce a missing value.",
                  "",
                  "{title:Source}", "",
                  "{pstd}"] + PROV[scheme] + ["    {p_end}", ""]
            if origin == "isco88":
                L += [ISCO88COM_NOTE_ADDON, ""]
            if scheme == "macro":
                L += [ESEC_POINTER_SHORT, ""]
            L += ["{pstd}",
                  "    Class labels: {helpb _cwfcn_labels_mc_%s:labels_mc_%s()}"
                  % (scheme, scheme),
                  "    {p_end}", "",
                  REFS,
                  "{hline}",
                  "{asis}"]
            for r in rows:
                L.append("%s %s" % (r[0], " ".join("%3s" % x for x in r[1:])))
            path = os.path.join(OUT, "_cwfcn_%s.sthlp" % fn)
            write(path, L)
            made.append((path, "%d rows (%d filled)" % (len(rows), n_fallback)))

    # ---------------------------------------------------- 4-digit wrappers
    for origin, (stem, keyfn, collapse, nicesrc, wrapname) in SOURCES.items():
        for scheme, (sname, ncls, sdesc) in SHIPPED_SCHEMES.items():
            fn = "mc_%s_to_%s" % (wrapname, scheme)
            L = header(fn, "Translate 4-digit %s to %s" % (nicesrc, sname))
            L += ["{title:Syntax}", "",
                  "        {cmd:mc.%s_to_%s(}{it:varname} {it:case}{cmd:)}"
                  % (wrapname, scheme),
                  "",
                  "{pstd}",
                  "    where {it:varname} contains 4-digit %s codes" % nicesrc,
                  "    and {it:case} selects the employment status column.",
                  "",
                  "{pstd}",
                  "    Typical usage:",
                  "",
                  "        {cmd:mc.%s_to_%s(}{it:varname} "
                  "{cmd:case.mcempstat(}{it:sempl} {it:supvis}{cmd:)}{cmd:)}"
                  % (wrapname, scheme),
                  "",
                  "{pstd}",
                  "    with {it:sempl} and {it:supvis} as described in",
                  "    {helpb _cwcasefcn_mcempstat:case.mcempstat()}.",
                  "",
                  "{title:Description}", "",
                  "{pstd}",
                  "    {helpb crosswalk} table translating 4-digit %s codes to" % nicesrc,
                  "    the %s. Note that the Multilevel Socio-Economic Classes" % sdesc,
                  "    are defined at the level of minor ISCO groups",
                  "    (3 digit); that is, all unit groups within a minor group",
                  "    translate into the same class.",
                  "",
                  CASEDOC,
                  "{title:Source}", "",
                  "{pstd}"] + PROV[scheme] + ["    {p_end}", "",
                  "{pstd}",
                  "    {cmd:%s()} is implemented as a wrapper for" % fn,
                  "    {helpb _cwfcn_%s:%s()} followed by" % (collapse, collapse),
                  "    {helpb _cwfcn_mc_%s_3_to_%s:mc_%s_3_to_%s()}."
                  % (origin, scheme, origin, scheme),
                  "    {p_end}", ""]
            if origin == "isco88":
                L += [ISCO88COM_NOTE_ADDON, ""]
            if scheme == "macro":
                L += [ESEC_POINTER_SHORT, ""]
            L += ["{pstd}",
                  "    Class labels: {helpb _cwfcn_labels_mc_%s:labels_mc_%s()}"
                  % (scheme, scheme),
                  "    {p_end}", "",
                  REFS,
                  "{hline}",
                  "{asis}",
                  "." + collapse,
                  ".mc_%s_3_to_%s" % (origin, scheme)]
            path = os.path.join(OUT, "_cwfcn_%s.sthlp" % fn)
            write(path, L)
            made.append((path, "wrapper"))

    # ------------------------------------------ microclass (no case)
    # 77 categories, ISCO-08 only, purely occupational. Kept at 4-digit
    # unit-group resolution, so it is a direct table rather than a wrapper
    # through crosswalk's 4-to-3 digit collapse, which would lose that detail.
    rows = read_src("isco08", "microclass")
    fn = "mc_isco08_to_microclass"
    L = header(fn, "Translate 4-digit ISCO-08 to the microclass scheme")
    L += ["{title:Syntax}", "",
          "        {cmd:mc.isco08_to_microclass(}{it:varname}{cmd:)}",
          "",
          "{pstd}",
          "    where {it:varname} contains 4-digit ISCO-08 codes. No",
          "    {help crosswalk##case:case} argument is used.",
          "",
          "{title:Description}", "",
          "{pstd}",
          "    {helpb crosswalk} table translating 4-digit ISCO-08 codes to the",
          "    microclass scheme (77 categories).",
          "",
          "{pstd}",
          "    Unlike the other {cmd:mc.} tables this one is purely",
          "    occupational: it does not vary by employment relation, so it has",
          "    a single destination column and takes no case argument.",
          "",
          "{pstd}",
          "    Keys are 4-digit ISCO-08 codes right-padded with zeros: 1000 is a",
          "    major group, 1100 a sub-major group, 1110 a minor group and 1111",
          "    a unit group. A code is matched against its unit group first, then",
          "    its minor, sub-major and major group. The table resolves at",
          "    unit-group level, so it is not routed through",
          "    {helpb _cwfcn_isco08_to_isco08_3:isco08_to_isco08_3()}.",
          "",
          "{title:Source}", "",
          "{pstd}",
          "    Crosswalk file for the 77-category microclass",
          "    scheme, documented in Smallenbroek, Hertel and Barone (n.d.);",
          "    see References.",
          "    {p_end}", "",
          MICROCLASS_NOTE, "",
          "{pstd}",
          "    Class labels:",
          "    {helpb _cwfcn_labels_mc_microclass:labels_mc_microclass()}",
          "    {p_end}", "",
          REFS_MICROCLASS,
          "{hline}",
          "{asis}"]
    for r in rows:
        L.append("%s %s" % (r[0], r[1]))
    path = os.path.join(OUT, "_cwfcn_%s.sthlp" % fn)
    write(path, L)
    made.append((path, "%d rows, no case" % len(rows)))

    # ---------------------------------------------------- label sets
    for scheme, (sname, ncls, sdesc) in list(SHIPPED_SCHEMES.items()) + [
            ("microclass", ("microclass scheme", 77,
                            "microclass scheme (77 categories)"))]:
        if scheme == "microclass":
            # 77 labels, straight from the micro08 value label in the source
            # .dta via tools/make_tables.do
            items = []
            for line in io.open(os.path.join(BUILD, "labels_microclass.txt"),
                                encoding="utf-8"):
                line = line.strip()
                if line:
                    val, _, text = line.partition(" ")
                    items.append((int(val), text.strip().strip('"')))
        else:
            items = LABELS[scheme]
        body = ['%-4s "%s"' % (v, t) for v, t in items]
        L = header("labels_mc_%s" % scheme, "%s class labels (English)" % sname)
        L += ["{title:Description}", "",
              "{pstd}",
              "    {helpb crosswalk} label set for the %s." % sdesc,
              "    Picked up automatically by the {cmd:mc.}{it:origin}{cmd:_to_%s()}"
              % scheme,
              "    tables when the prefix syntax {cmd:mc.} is used.",
              "    {p_end}", "",
              "{pstd}",
              "    Taken from the value labels carried by the source",
              "    crosswalk files.",
              "    {p_end}",
              "{hline}",
              "{asis}"]
        L += [b for b in body if b.strip()]
        path = os.path.join(OUT, "_cwfcn_labels_mc_%s.sthlp" % scheme)
        write(path, L)
        made.append((path, "%d labels" % len([b for b in body if b.strip()])))

    for p, n in made:
        print("%-58s %s" % (p, n))


if __name__ == "__main__":
    main()
