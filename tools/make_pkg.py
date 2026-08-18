"""Write multiclass-addon/crosswalk_multiclass.pkg and stata.toc.

This .pkg is for -net install- from a local directory or a GitHub raw URL,
where every file sits in one flat directory. SSC does NOT use it: the archive
generates its own .pkg from the RePEc template, and that generated file routes
underscore-prefixed files through ../_/ because SSC stores them in a shared
directory. Both facts are why the SSC zip excludes this file.

Format follows the SSC house style (see kldbrecode.pkg): a quoted upper-case
package name in the title line, KW: keyword lines, a Requires line naming the
SSC dependencies, Distribution-Date, and Author/Support pairs with @ doubled.

Run from D:/work/multiclass-package.
"""

import io
import os
import datetime

OUT = "multiclass-addon"
PKG = "crosswalk_multiclass"

TITLE = ("module providing crosswalk tables to translate ISCO-88com and "
         "ISCO-08 into the MultiClass class schemes")

DESC = """\
crosswalk_multiclass is an add-on for the crosswalk package by Ben
Jann. It provides crosswalk tables translating ISCO-88com and ISCO-08
occupational codes into class schemes of the MultiClass schema:
MicroSEC (30 classes), the meso-class scheme (18 classes), the ESeC
multi-purpose variant ESeC-MP (11 classes), and, for ISCO-08, a
77-category micro-class scheme. MicroSEC, meso-class and ESeC-MP are
defined jointly over occupation and employment relation, so those
tables carry one destination column per employment status, and two
case functions are supplied to construct that argument; the
micro-class scheme is purely occupational and takes no case. Tables
are provided for 4-digit ISCO codes and, directly, for 3-digit ISCO
minor groups. The schemes nest: MicroSEC, the meso-class and ESeC-MP
each aggregate to the European Socio-economic Classification (ESeC).
This package does not duplicate plain ESeC itself, since crosswalk
already provides isco88_to_esec() and isco08_to_esec(); see help
crosswalk_multiclass for details and the correct case functions to use
with them. The package contains no ado-file and defines no command of
its own; all recoding is carried out by the crosswalk command.\
"""

KEYWORDS = ["ISCO-88com", "ISCO-08", "occupation", "social class", "ESeC",
            "ESeC-MP", "MicroSEC", "micro-class", "meso-class",
            "class scheme", "crosswalk"]

REQUIRES = "Stata version 14 and crosswalk, moremata from SSC (q.v.)"

AUTHORS = [("Oscar Smallenbroek", "", "")]

EXCLUDE = {"README.md", "crosswalk_multiclass.pkg", "stata.toc", "LICENSE"}


def main():
    files = sorted(f for f in os.listdir(OUT)
                   if f not in EXCLUDE and not f.startswith("."))
    # entry-point help first, as SSC does
    entry = PKG + ".sthlp"
    if entry in files:
        files.remove(entry)
        files.insert(0, entry)

    date = datetime.date.today().strftime("%Y%m%d")
    L = ["v 3",
         "d '%s': %s" % (PKG.upper(), TITLE),
         "d"]
    for line in DESC.split("\n"):
        L.append("d " + line if line else "d")
    L.append("d")
    for k in KEYWORDS:
        L.append("d KW: %s" % k)
    L.append("d")
    L.append("d Requires: %s" % REQUIRES)
    L.append("d")
    L.append("d Distribution-Date: %s" % date)
    L.append("d")
    for name, affil, email in AUTHORS:
        L.append("d Author: %s%s" % (name, (", " + affil) if affil else ""))
        if email:
            L.append("d Support: email %s" % email.replace("@", "@@"))
        L.append("d")
    L += ["f %s" % f for f in files]

    p = os.path.join(OUT, PKG + ".pkg")
    io.open(p, "w", encoding="ascii", newline="\n").write("\n".join(L) + "\n")

    io.open(os.path.join(OUT, "stata.toc"), "w", encoding="ascii",
            newline="\n").write("v 3\np %s %s\n" % (PKG, TITLE))

    print("wrote %s (%d files listed)" % (p, len(files)))
    print("wrote %s" % os.path.join(OUT, "stata.toc"))


if __name__ == "__main__":
    main()
