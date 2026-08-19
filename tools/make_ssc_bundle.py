"""Build the SSC submission bundle for crosswalk_multiclass.

Follows http://repec.org/bocode/s/sscsubmit.html:
  - materials go in a zip emailed to the archive maintainer
  - the .pkg and stata.toc are NOT included: "It is not necessary nor
    desirable to generate a Stata-format package (.pkg) file, since the SSC
    archive software generates the package file automatically from the RePEc
    template." They stay in the repo for -net install- from a local dir/GitHub.
  - the covering email must give the package name, title line, abstract, and
    any SSC dependencies.

Run from D:/work/multiclass-package.
"""

import io
import os
import zipfile

PKG = "crosswalk_multiclass"
SRC = "multiclass-addon"
OUT = "dist"

# Excluded from the SSC zip (repo-only files).
EXCLUDE = {"crosswalk_multiclass.pkg", "stata.toc", "README.md"}

TITLE = ("crosswalk_multiclass: Crosswalk tables to translate ISCO-88com and "
         "ISCO-08 into the Multilevel Socio-Economic Classes schemes")

ABSTRACT = """\
crosswalk_multiclass is an add-on for the crosswalk package (Ben Jann). It
provides crosswalk tables translating ISCO-88com and ISCO-08 occupational codes
into the Multilevel Socio-Economic Classes (MSEC) schemes -- Micro-SEC (30
classes), Meso-SEC (18 classes), and Macro-SEC (11 classes, ESEC plus
differentiation of SC I and II) -- plus, for ISCO-08 only, a separate
77-category micro-class scheme that is not part of MSEC. Micro-SEC, Meso-SEC
and Macro-SEC are defined jointly over occupation and employment relation, so
those tables carry one destination column per employment status; two case
functions are supplied to build that argument, either from a self-employment
indicator and a supervisory/employee-count variable, or from a status variable
already coded 1-5. The micro-class scheme is purely occupational and takes no
case argument. Tables are provided for 4-digit ISCO codes and, directly, for
3-digit ISCO minor groups. The MSEC schemes nest: Micro-SEC, Meso-SEC and
Macro-SEC each aggregate to the European Socio-economic Classification (ESeC).
This package does not duplicate plain ESeC itself, since crosswalk already
provides isco88_to_esec() and isco08_to_esec(); see help crosswalk_multiclass
for details and the correct case functions to use with them. The package
contains no ado-file and defines no command of its own; all recoding is
carried out by crosswalk.\
"""

REQUIRES = ["crosswalk (Ben Jann, SSC)", "moremata 2.0.0 or newer (Ben Jann, SSC)"]

KEYWORDS = ["ISCO", "occupation", "social class", "ESeC", "Macro-SEC",
            "micro-class", "Meso-SEC", "Micro-SEC", "MSEC", "class scheme", "crosswalk", "recode"]


def main():
    if not os.path.isdir(OUT):
        os.makedirs(OUT)

    files = sorted(f for f in os.listdir(SRC)
                   if f not in EXCLUDE and not f.startswith("."))
    # sanity: everything shipped must be a help file
    bad = [f for f in files if not f.endswith(".sthlp") and f != "LICENSE"]
    assert not bad, "unexpected files in the bundle: %s" % bad

    zpath = os.path.join(OUT, PKG + ".zip")
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            p = os.path.join(SRC, f)
            data = io.open(p, "rb").read()
            assert b"\r\n" not in data, "%s has CRLF line endings" % f
            assert all(b < 128 for b in bytearray(data)), "%s is not ASCII" % f
            z.write(p, arcname=f)

    note = []
    note.append("SSC submission: %s" % PKG)
    note.append("=" * 62)
    note.append("")
    note.append("Submission type : NEW package")
    note.append("Package name    : %s" % PKG)
    note.append("Author          : Oscar Smallenbroek")
    note.append("Zip file        : %s" % os.path.basename(zpath))
    note.append("Files           : %d (all .sthlp; see listing below)" % len(files))
    note.append("")
    note.append("Title line")
    note.append("-" * 62)
    note.append(TITLE)
    note.append("")
    note.append("Abstract / description")
    note.append("-" * 62)
    note.append(ABSTRACT)
    note.append("")
    note.append("Requires (other SSC materials)")
    note.append("-" * 62)
    for r in REQUIRES:
        note.append("  - %s" % r)
    note.append("")
    note.append("Suggested keywords")
    note.append("-" * 62)
    note.append("  " + ", ".join(KEYWORDS))
    note.append("")
    note.append("Notes for the maintainer")
    note.append("-" * 62)
    note.append("  - The package contains no ado-file: it is a data-only add-on")
    note.append("    for crosswalk, in the same form as kldbrecode. It therefore")
    note.append("    defines no command name and carries no -version- statement.")
    note.append("  - Minimum Stata version is 14, inherited from crosswalk.")
    note.append("  - All files are plain ASCII with LF line endings, and all")
    note.append("    help files use the .sthlp extension.")
    note.append("  - No .pkg or stata.toc is included, per the submission notes.")
    note.append("  - crosswalk_multiclass.sthlp is the entry-point help file.")
    note.append("")
    note.append("File listing")
    note.append("-" * 62)
    for f in files:
        note.append("  %s" % f)
    note.append("")

    npath = os.path.join(OUT, "SSC_SUBMISSION.txt")
    io.open(npath, "w", encoding="ascii", newline="\n").write("\n".join(note) + "\n")

    size = os.path.getsize(zpath)
    print("wrote %s  (%d files, %.1f KB)" % (zpath, len(files), size / 1024.0))
    print("wrote %s" % npath)


if __name__ == "__main__":
    main()
