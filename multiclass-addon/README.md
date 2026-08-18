# crosswalk_multiclass

An **add-on for the [`crosswalk`](https://github.com/benjann/crosswalk) package**
by Ben Jann, providing crosswalk tables that translate **ISCO-88com** and
**ISCO-08** into the class schemes of the MultiClass schema:

| scheme | classes | destination | source |
|---|---|---|---|
| MicroSEC | 30 | `micro` | ISCO-88com, ISCO-08 |
| meso-class | 18 | `meso` | ISCO-88com, ISCO-08 |
| ESeC-MP | 11 | `esecmp` | ISCO-88com, ISCO-08 |
| micro-class | 77 | `microclass` | ISCO-08 only |

Like [`kldbrecode`](https://github.com/hagerhardt/kldbrecode), this package
contains **no `.ado` file** — it is pure crosswalk data. All recoding is done by
the `crosswalk` command.

**No plain ESeC table.** `crosswalk` already ships `isco88_to_esec()` and
`isco08_to_esec()`, so this package doesn't duplicate them — see
[Where is ESeC?](#where-is-esec) below before you go looking for
`mc.isco08_to_esec()`.

If you want a self-contained command instead, with no `crosswalk`/`moremata`
dependency, use the sibling [`multiclass`](../multiclass) package. The two
produce identical results — verified by running both, see *Parity* below.

## Requirements

- Stata 14 or newer
- [`crosswalk`](https://github.com/benjann/crosswalk) — `ssc install crosswalk, replace`
- [`moremata`](http://fmwww.bc.edu/RePEc/bocode/m) 2.0.0+ — `ssc install moremata, replace`

## Install

From SSC, once the package is accepted:

```stata
ssc install crosswalk_multiclass, replace
```

From a local directory or a GitHub raw URL:

```stata
net install crosswalk_multiclass, from("D:/work/multiclass-package/multiclass-addon") replace
```

or simply put the directory on the ado-path:

```stata
adopath ++ "D:/work/multiclass-package/multiclass-addon"
```

Then `help crosswalk_multiclass`.

## Usage

The tables use crosswalk's **prefix syntax**: type them as `mc.`*origin*`_to_`*scheme*`()`.
The prefix is what makes crosswalk pick up the `labels_mc_*` label sets rather
than any same-named labels from crosswalk itself or another add-on.

Build the case from a self-employment indicator and a supervisory/employee-count
variable:

```stata
crosswalk micro  = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))
crosswalk esecmp = mc.isco88com_to_esecmp(isco88 case.mcempstat(selfemp nsuperv))
```

If your data already carries employment status on the 1–5 scale used by the
MultiClass source crosswalk files, use the other case function:

```stata
crosswalk micro = mc.isco08_to_micro(isco08 case.mcstatus5(empstat))
```

All three employment-relation schemes:

```stata
foreach s in micro meso esecmp {
    crosswalk `s' = mc.isco08_to_`s'(isco08 case.mcempstat(selfemp nsuperv))
}
```

3-digit data is supported directly, without the 4-digit wrapper:

```stata
crosswalk meso = mc.isco08_3_to_meso(isco08_3digit case.mcstatus5(empstat))
```

The micro-class scheme is purely occupational and takes **no case argument**:

```stata
crosswalk microclass = mc.isco08_to_microclass(isco08)
```

## Employment status — read this before use

MicroSEC, the meso-class and ESeC-MP are defined jointly over occupation **and
employment relation**, so the case is not optional for those three tables. The
columns follow the same convention as the ESeC tables that ship with
`crosswalk`:

| case | meaning |
|---|---|
| 1 | employment status unknown |
| 2 | employed, without supervisory status |
| 3 | employed, with supervisory status |
| 4 | self-employed, no employees |
| 5 | self-employed, 1–9 employees |
| 6 | self-employed, 10 or more employees |

Two consequences worth understanding:

**Column 1 is `.` in every table.** MultiClass has no simplified variant for
unknown employment status. crosswalk sends every observation whose case is
missing or out of range to column 1 (`// - use column 1 for obs with invalid
case` in `crosswalk.ado`), so coding column 1 as missing is what makes those
observations come back uncoded rather than silently picking up another class.

**Do not pass a bare 1–5 status variable as the case.** This numbering runs in
the opposite direction to the 1–5 scale used by the source crosswalks, so a
bare variable selects the wrong columns without any error. Route it through
`case.mcstatus5()`. The live test demonstrates the difference:

| `empstat` | bare variable | via `case.mcstatus5()` |
|---|---|---|
| 1 | `.` | 11 |
| 2 | 93 | 62 |
| 3 | 81 | 60 |
| 4 | 60 | 81 |
| 5 | 62 | 93 |

Because the numbering matches crosswalk's ESeC convention exactly,
`case.esec88()` also works with these tables and gives identical results to
`case.mcempstat()` (verified in the test suite).

## Contents

| file group | count | what |
|---|---|---|
| `_cwfcn_mc_isco{88,08}_3_to_*.sthlp` | 6 | 3-digit minor group → class (micro, meso, esecmp), 6 case columns |
| `_cwfcn_mc_isco{88com,08}_to_*.sthlp` | 6 | 4-digit wrappers for those 6 |
| `_cwfcn_mc_isco08_to_microclass.sthlp` | 1 | 4-digit ISCO-08 → micro-class, direct, no case |
| `_cwfcn_labels_mc_*.sthlp` | 4 | label sets, picked up via the `mc.` prefix |
| `_cwcasefcn_mcempstat.sthlp` | 1 | case from `sempl`/`supvis` |
| `_cwcasefcn_mcstatus5.sthlp` | 1 | case from a 1–5 status variable |

The employment-relation 4-digit tables are wrappers in crosswalk's own idiom —
the same structure crosswalk uses for `isco08_to_esec()`. For example
`_cwfcn_mc_isco08_to_meso.sthlp` is just:

```
.isco08_to_isco08_3
.mc_isco08_3_to_meso
```

so the 4-digit → 3-digit collapse is crosswalk's own table, not a duplicate
shipped here. `mc.isco08_to_microclass()` is not a wrapper: it resolves at
unit-group (4-digit) precision directly, since the micro-class scheme was
built at that resolution rather than at the minor-group level the other
schemes use.

## Where is ESeC?

There is no `mc.isco08_to_esec()` or `mc.isco88com_to_esec()`. `crosswalk`
already ships `isco88_to_esec()` and `isco08_to_esec()` for plain 9-class
ESeC, so duplicating them here would only risk the two falling out of step —
use those directly:

```stata
crosswalk esec = isco08_to_esec(isco08 case.esec(selfemp nsuperv))
```

**Their case function is not `case.mcempstat()`.** `isco88_to_esec()` takes
`case.esec88()` (6 columns, with an "unknown" case — the same numbering used
throughout this add-on), while `isco08_to_esec()` takes `case.esec()` (5
columns, *no* "unknown" case). Passing the wrong one won't error; it will
silently select the wrong columns.

`mc.<origin>_to_esecmp()` collapses to the same ESeC classes with the rule
{1,2}→1, {3,4}→2, 5→3, 6→4, 7→5, 8→6, 9→7, 10→8, 11→9. That collapse and
crosswalk's own ESeC table are **independently sourced** — ours from the
MicroSEC crosswalk files, theirs from the Harrison/Rose ESeC matrix. Checked
against every 4-digit code either source recognizes (`tools/test_addon_live.do`,
section B3):

| | comparable cells | disagreements |
|---|---|---|
| ISCO-08 | 2,930 | 0 |
| ISCO-88(COM) | 2,531 | 0 |

("Comparable" excludes cells where only one source has a row; those coverage
gaps run in both directions and aren't disagreements.) ISCO-08 needed no
adjustment to reach that. ISCO-88(COM) originally disagreed on 8 cells,
confined to 2 minor groups: 011 (Commissioned armed forces officers) and 621
(Subsistence agricultural and fishery workers) — both classic edge cases where
ESeC's employment-relation categories don't apply cleanly to the occupation.
Those two are therefore hand-set to crosswalk's own native `isco88_to_esec()`
values rather than derived.

The override covers **micro and meso as well as ESeC-MP**, so the three schemes
still [nest](#the-schemes-nest). Setting only ESeC-MP would have left micro and
meso aggregating to a different ESeC class for these codes (10 and 8 nesting
violations respectively). The replacements are:

| minor group | column | micro | meso | ESeC-MP | ESeC |
|---|---|---|---|---|---|
| 011 | supervisory | 30 Lower managers | 22 Lower administrative managers and professionals | 3 Lower Manager | 2 |
| 011 | all others | 52 Armed forces | 23 Associate administrative professionals | 5 Higher-grade White-collar | 3 |
| 621 | all | 70 Primary production self-employed workers | 15 Self-employed agriculture | 7 Self-employed and Small Employer agriculture | 5 |

Each replacement is the class that already corresponds to the ESeC-MP class
being set, and every micro→meso pairing above is the one the deterministic
30→18 map already uses everywhere else, so no new pairing was introduced.
These are the only hand-set values in the package; see `OVERRIDE` in
`tools/make_addon.py`.

## Two different "micro" schemes

This package ships **two unrelated 30-and-77 schemes, both loosely called
"micro"**, and confusing them will give the wrong answer:

- **`micro` (MicroSEC, 30 classes)** is jointly assigned with employment
  relation, part of the same class hierarchy as `meso`, `esec` and `esecmp`.
  Assessed alongside ESeC-MP in Hertel, Barone and Smallenbroek (2025) — but
  that paper assessed an earlier *prototype* of MicroSEC
  ([osf.io/preprints/socarxiv/962q3_v1](https://osf.io/preprints/socarxiv/962q3_v1)),
  not the version shipped here. The paper documenting this version is
  currently under review.
- **`microclass` (77 categories, ISCO-08 only)** is purely occupational,
  following Grusky, Weeden and Sorensen (2000) and Weeden and Grusky (2005),
  emulating Jonsson et al. (2009). Documented in Smallenbroek, Hertel and
  Barone ([OSF preprint](https://osf.io/preprints/socarxiv/xaqju_v1)). It does
  not vary by employment status and takes no case argument.

## How the tables were built

The class values come from three source crosswalk files: `isco88com to MSECS
v2 FINAL.dta`, `isco08-to-meso.dta`, and `isco08 to microclass.dta`, which do
not all carry the same schemes. Two of the shipped combinations are derived,
each verified against the sources first: meso-class from micro-class
(deterministic 30→18), and ESeC-MP from (micro-class, employment status)
(deterministic, 59 cells). Native values always win over derived ones. Each
table's `Source` section in its `.sthlp` records which route it took.
`microclass` is a direct lookup with no derivation and no employment-status
dimension.

### The schemes nest

MicroSEC, the meso-class and ESeC-MP each determine the ESeC class on their
own — `30 MicroSEC → 18 meso → 9 ESeC`, and `11 ESeC-MP → 9 ESeC`. The
meso-class encodes this directly: its second digit *is* the ESeC class, with
meso 14 and 15 → ESeC 4 and 5. See [Where is ESeC?](#where-is-esec) for that
collapse rule and for why plain ESeC itself isn't shipped as a table here.

Two ISCO-88com cells did not nest in the source file and are reassigned to the
micro-class the other employment statuses of the same ISCO code already use:

| ISCO-88com | status | micro was | micro now | meso | ESeC |
|---|---|---|---|---|---|
| 2400 | self-employed | 42 Cultural associate professionals | **20 Business operation professionals** | 21 | 1 |
| 7300 | employees | 102 Industrial workers | **80 Technical supervisors** | 46 | 6 |

Both agree with the native ESeC class the source carries, which they previously
contradicted. See the [`multiclass` README](../multiclass/README.md) for the
full derivation notes.

### Rows filled from a parent group

The source crosswalks are defined at minor-group level with aggregate rows for
sub-major and major groups. The 3-digit tables here carry a row for **every**
3-digit code that crosswalk's collapse tables can emit — 183 for ISCO-08, 155
for ISCO-88 — so that no code falls through the chain unnoticed. Of those, 1
(ISCO-08) and 9 (ISCO-88) are minor groups the source crosswalk does not list
separately; they are filled from the enclosing sub-major or major group.

The ISCO-88 case matters in practice: minor groups 112, 113, 324, 515, 523 and
620 exist in ISCO-88 but not in ISCO-88com. Without those filled rows, plain
ISCO-88 data came back missing for those codes while the direct 3-digit table
coded them — the two routes disagreed on 60 cells until this was fixed.

## Testing

`tools/test_addon_live.do` runs `crosswalk` for real. Its only dependencies are
`crosswalk`, `moremata` and this package: there is no separate command to
compare against and no Python in the loop, which is the point — `crosswalk` is
both the thing under test and the only oracle a user has.

- **Every shipped table loads.** `crosswalk list` reads all 13 tables, and
  `crosswalk dir` sees the add-on.
- **Full grid, 4 routes.** Every 4-digit code crosswalk's own collapse tables
  know about, × all 5 employment statuses, × the 3 employment-relation schemes
  — 2,950 rows for ISCO-08 and 2,600 for ISCO-88 — resolved four ways: the
  4-digit wrapper with numeric input, with zero-padded string input, with a
  hand-built case variable, and the 3-digit table applied directly to
  crosswalk's own collapsed code. **0 disagreements.** The fourth route is the
  one that catches a 3-digit table missing a row the collapse can emit.
- **ESeC parity.** Collapsing ESeC-MP reproduces crosswalk's own native
  `isco88_to_esec()`/`isco08_to_esec()` on every comparable cell — 2,531 and
  2,930 of them, **0 disagreements**. Since the two are independently sourced,
  this is a genuine external check rather than a restatement. See
  [Where is ESeC?](#where-is-esec).
- **Nesting.** Over that same full grid, micro-class, meso-class and ESeC-MP
  each determine the ESeC class on their own, on both ISCO versions.
- **Micro-class.** Unit-group detail (which the other schemes collapse away) is
  confirmed to survive: 1111 and 1120 must not return the same class.
- **Case functions.** `case.mcempstat()` and `case.mcstatus5()` agree wherever
  they describe the same employment relation, `case.esec88()` is
  interchangeable with `case.mcempstat()` for these tables, `supvis` may be
  omitted, and a missing `sempl` comes back uncoded rather than silently
  landing in column 1.
- **Invalid input** (out-of-range codes, non-ISCO codes, out-of-range and
  missing statuses) comes back missing.
- **The bare-case trap** is asserted to still be a trap: passing a raw 1–5
  variable must *not* agree with `case.mcstatus5()`, which is what makes that
  case function necessary.

## Regenerating

From `D:/work/multiclass-package`, run `tools/make_tables.do` in Stata. It
reads the three source `.dta` files and writes, into `build/`, both the class
tables (`d_*.txt`) and the 3-digit resolution (`addon3_*.csv`) — the latter by
walking each 3-digit code crosswalk can emit through the same minor →
sub-major → major fallback the lookup uses. Then:

```bash
python tools/make_addon.py
```

which wraps those into the shipped `.sthlp` tables and applies the two hand-set
minor groups. Finally re-run `tools/test_addon_live.do` in Stata.

Note that the fallback is on the **key**, not the cell: a minor group present
in the table is used even where individual employment-status cells are missing,
and only a minor group absent from the table falls back to its sub-major group.
Getting that backwards silently changes which codes come back uncoded.

## SSC submission

`dist/` holds the submission bundle, rebuilt by `python tools/make_ssc_bundle.py`:

- `crosswalk_multiclass.zip` — the 21 files to email to the archive maintainer
- `SSC_SUBMISSION.txt` — package name, title line, abstract, keywords and the
  declared SSC dependencies, as the covering email needs them

Per the [submission notes](http://repec.org/bocode/s/sscsubmit.html), the zip
deliberately omits `crosswalk_multiclass.pkg` and `stata.toc`: SSC generates its
own `.pkg` from the RePEc template, and that generated file routes
underscore-prefixed files through `../_/` because the archive keeps them in a
shared directory. The `.pkg` kept in this repo uses flat paths instead, for
`net install` from a local directory or GitHub.

Checks run against the guidelines (`tools/test_ssc_compliance.do`):

- every table works with `set varabbrev off`, across all call forms, with 0
  result differences
- the add-on ships no ado-file, so it defines no command name and carries no
  `version` statement; minimum Stata version 14 is inherited from `crosswalk`
- all files are plain ASCII with LF endings and use `.sthlp`, never `.hlp`
- all filenames are checked against the SSC archive listings for collisions —
  none, and the package name is free
- ISCO-88(COM)-sourced tables carry the same sourcing note `crosswalk` gives
  its own `isco88_to_esec()`, since our `micro`/`meso`/`esecmp` tables are
  built on the same EU variant of ISCO-88
- the `.pkg` file list is complete and self-sufficient: installing only the
  declared files and nothing else still runs (`tools/test_installed.do`)

## References

Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
Approaches to Class Analysis. *European Societies* 1–65.
[doi:10.1162/euso_a_00044](https://doi.org/10.1162/euso_a_00044).

Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class Hierarchies in
Postindustrial Societies: A Criterion and Construct Validation of EGP and ESEC
Across 31 Countries. *Sociological Methods & Research* 53(3):1412–52.
[doi:10.1177/00491241221134522](https://doi.org/10.1177/00491241221134522).

Smallenbroek, O., F. R. Hertel, C. Barone. n.d. Adapting the Microclass Schema
for Cross-national Research.
[osf.io/preprints/socarxiv/xaqju_v1](https://osf.io/preprints/socarxiv/xaqju_v1).

Jonsson, J. O., D. B. Grusky, M. Di Carlo, R. Pollak, M. C. Brinton. 2009.
Microclass Mobility: Social Reproduction in Four Countries. *American Journal
of Sociology* 114(4):977–1036.
[doi:10.1086/596566](https://doi.org/10.1086/596566).

Weeden, K. A., D. B. Grusky. 2005. The Case for a New Class Map. *American
Journal of Sociology* 111(1):141–212.
[doi:10.1086/428815](https://doi.org/10.1086/428815).

Grusky, D. B., K. A. Weeden, J. B. Sørensen. 2000. The Case for Realism in
Class Analysis. *Political Power and Social Theory* 14:291–305.

Harrison, E., D. Rose. 2006. The European Socio-economic Classification (ESeC)
User Guide. Institute for Social and Economic Research, University of Essex.

Jann, B. 2025. crosswalk: Stata module to recode variables based on crosswalk
tables. Statistical Software Components S459534, Boston College Department of
Economics.

## Author

Oscar Smallenbroek
