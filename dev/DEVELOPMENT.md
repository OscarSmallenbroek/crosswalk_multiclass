# Development notes — crosswalk_multiclass

Everything in this file is for **maintainers**. None of it belongs in the help
files or the user-facing README: a user of the add-on never sees the underlying
tables, so provenance, derivation rules and build mechanics live here instead.

The rule to hold to when editing documentation: help files and the root
`README.md` answer *how do I use this and what should I cite*. This file answers
*where did these numbers come from and how do I regenerate them*.

---

## Repository layout

```
README.md              user-facing GitHub landing page
dev/DEVELOPMENT.md     this file
crosswalks/            the three source .dta files
multiclass-addon/      the package itself (shipped)
tools/                 build chain + test suite
build/  dist/          generated, git-ignored
```

`papers/` and `original crosswalk/` are local reference material and are
git-ignored.

## Source data

Three `.dta` files in `crosswalks/`, which do not all carry the same schemes:

| file | provides |
|---|---|
| `isco88com to MSECS v2 FINAL.dta` | micro (`msecs_int`), native ESeC (`esec88`) |
| `isco08-to-meso.dta` | micro (`microSEC_int`), meso (`mesoSEC`), Macro-SEC (`esec08_MP`) |
| `isco08 to microclass.dta` | microclass (`micro_class`, 77) |

Note that Multilevel Socio-Economic Class schemas include Macro-SEC, Meso-SEC, Micro-SEC. These all nest into ESEC and assignment is guided by employment relations.
 
The Microclass schema has another theoretical basis and is not nested in ESEC. It is based on occupational social closure and uses only ISCO codes for assignment.

## Jargon

Refer to the three nested schema as Multilevel Socio-Economic Classes (MSEC). 
These include Macro-SEC, Meso-SEC and Micro-SEC. 

Naming convention avoids confusion with microclasses (77 categories). Refer to it as microclass NOT micro-class

Facts established by inspecting them:

- **`emp_stat` coding is 1 = large employer, 2 = small employer,
  3 = self-employed, 4 = supervisor, 5 = employee.** This is the *reverse* of
  crosswalk's column order, and it has no "unknown" category. The shipped
  tables use crosswalk's convention instead (case = `7 - emp_stat`, column 1 =
  unknown). The 5-column shape of the source is an implementation detail and is
  deliberately not exposed in the add-on's design.
- All shipped tables use one 4-digit right-padded key convention:
  1000 major, 1100 sub-major, 1110 minor, 1111 unit group.
- Meso-SEC is a deterministic function of Micro-SEC (30 → 18), verified no violations.
- Macro-SEC is a deterministic function of (Micro-SEC, `emp_stat`), 59 cells.
- Macro-SEC collapses to ESeC: {1,2}→1, {3,4}→2, 5→3, 6→4, 7→5, 8→6, 9→7,
  10→8, 11→9.

Two of the shipped combinations are **derived**, each verified against the
sources first: meso from micro, and Macro-SEC from (micro, employment status).
Native values always win over derived ones. `microclass` is a direct lookup
with no derivation and no employment-status dimension.

### Two source cells that did not nest

Two ISCO-88com cells carried a micro-class that did not aggregate to their own
native ESeC. Both are reassigned in `tools/make_tables.do` to the micro-class
the other employment statuses of the same ISCO code already use:

| ISCO-88com | status | micro was | micro now | meso | ESeC |
|---|---|---|---|---|---|
| 2400 | self-employed | 42 Cultural associate professionals | **20 Business operation professionals** | 21 | 1 |
| 7300 | employees | 102 Industrial workers | **80 Technical supervisors** | 46 | 6 |

Both now agree with the native ESeC class the source carries, which they
previously contradicted.

## The 011/621 override

The only hand-set values in the package, ISCO-88 only.

Our Macro-SEC collapse and crosswalk's native `isco88_to_esec()` are
**independently sourced** — ours from the Micro-SEC files, theirs from the
Harrison/Rose matrix — and were never guaranteed to agree. They disagreed on 8
cells, all inside minor groups 011 (Commissioned armed forces officers) and 621
(Subsistence agricultural and fishery workers), both classic edge cases where
ESeC's employment-relation categories don't apply cleanly to the occupation.

Those two minor groups are hand-set in `OVERRIDE` in `tools/make_addon.py`.

**The override must cover micro and meso, not just Macro-SEC.** Setting only
Macro-SEC left micro and meso aggregating to a different ESeC class for these
codes — 10 micro and 8 meso nesting violations, every one of them traceable to
these two groups. Since all three schemes are advertised to nest, that made a
documented property false. Values, by crosswalk case 2–6:

| minor group | column | micro | meso | Macro-SEC | → ESeC |
|---|---|---|---|---|---|
| 011 | supervisory (case 3) | 30 Lower managers | 22 Lower administrative managers and professionals | 3 Lower Manager | 2 |
| 011 | all others | 52 Armed forces | 23 Associate administrative professionals | 5 Higher-grade White-collar | 3 |
| 621 | all | 70 Primary production self-employed workers | 15 Self-employed agriculture | 7 Self-employed and Small Employer agriculture | 5 |

These are not invented. Each replacement is the class that already corresponds
to the Macro-SEC class being set, and every micro→meso pairing (52→23, 30→22,
70→15) is the one the deterministic 30→18 map already uses everywhere else,
verified in both ISCO versions. The one genuine judgement call is 011's
supervisory column: crosswalk says ESeC 2, and a commanding role reads as the
"manager" half of that split, hence Lower managers.

Result: **0 ESeC disagreements and nesting intact**, on both ISCO versions.

## Rows filled from a parent group

The source crosswalks are defined at minor-group level with aggregate rows for
sub-major and major groups. The 3-digit tables carry a row for **every** 3-digit
code crosswalk's collapse tables can emit — 183 for ISCO-08, 155 for ISCO-88 —
so no code falls through the chain unnoticed. Of those, 1 (ISCO-08) and 9
(ISCO-88) are minor groups the source does not list separately and are filled
from the enclosing sub-major or major group.

This matters in practice: minor groups 112, 113, 324, 515, 523 and 620 exist in
ISCO-88 but not in ISCO-88com. Without those filled rows, plain ISCO-88 data
came back missing for those codes through the 4-digit wrapper while the direct
3-digit table coded them — **the two routes disagreed on 60 cells** until this
was fixed.

**The fallback is on the KEY, not the cell.** A minor group present in the table
is used even where individual employment-status cells are missing; only a minor
group absent from the table falls back to its sub-major, then major, group.
Getting that backwards silently changes which codes come back uncoded.

## Build chain

Run from the repository root, in order:

1. **`tools/make_tables.do`** (Stata) — reads the three `.dta` files, writes
   `build/d_*.txt` (the class tables) and `build/addon3_*.csv` (every 3-digit
   code resolved through the fallback above, by the `resolve3` program). This
   was once done by running a separate standalone command; doing it here means
   the add-on rebuilds from source with nothing but Stata and crosswalk. The
   rewrite was validated as byte-identical to what that command produced.
2. **`python tools/make_addon.py`** — wraps `build/` into the shipped `.sthlp`
   tables and applies `OVERRIDE`. Reads only `build/`.
3. **`python tools/make_pkg.py`** — writes `crosswalk_multiclass.pkg` and
   `stata.toc` with flat paths, for `net install` from GitHub or a local dir.
4. **`python tools/make_ssc_bundle.py`** — writes `dist/`.

### Things that will bite you

- **Class label text for micro/meso/macro is a curated dict (`LABELS`) inside
  `make_addon.py`, not re-read from the `.dta`.** It carries fixes — collapsed
  double spaces, and the source typo `Techincal` → `Technical` — that a raw
  re-read would silently lose. `microclass` labels do come from the `.dta`, via
  `build/labels_microclass.txt`. Label line format is `%-4s "%s"`.
- **`crosswalk_multiclass.sthlp`, the root `README.md` and
  `_cwcasefcn_mcempstat.sthlp` are hand-maintained**, not regenerated. After any
  change to `citations.py` or the wording in `make_addon.py`, grep those three by
  hand. An earlier citation swap silently failed to propagate for exactly this
  reason.
- **SSC requires plain ASCII with LF endings.** `citations.py` has
  `to_ascii`/`assert_ascii` guards that every generated `.sthlp` is routed
  through; a curled apostrophe from a source label slipped past once.
  `.gitattributes` pins `eol=lf` because `core.autocrlf` is on in this checkout
  and a fresh clone would otherwise hand back CRLF files.
- **`merge ..., keep(master match) update` silently drops updated rows**, because
  `update` reclassifies them as `_merge` 4/5 rather than 3. `resolve3` merges
  into suffixed variables instead.

## Testing

**The add-on must be verified using nothing but the Stata `crosswalk` package.**
No Python in the test loop and no comparison against any other package —
crosswalk is what actually executes these tables, so it is both the thing under
test and the only oracle a user has. Python is fine for *generating* tables,
never for checking them.

| file | what it asserts |
|---|---|
| `tools/test_addon_live.do` | the main suite — see below |
| `tools/test_ssc_compliance.do` | `varabbrev off`, no ado-file, entry-point help resolves |
| `tools/test_installed.do` | the `.pkg` declares every shipped `.sthlp` and vice versa, then runs all 13 tables |

`test_addon_live.do` covers:

- **Full grid, 4 routes.** Every 4-digit code crosswalk's collapse can emit ×
  5 employment statuses × 3 schemes × both ISCO versions — 2,950 and 2,600 rows
  — resolved four ways: 4-digit wrapper with numeric input, with zero-padded
  string input, with a hand-built case, and the 3-digit table applied directly
  to crosswalk's own collapsed code. The fourth route is what catches a 3-digit
  table missing a row the collapse can emit.
- **D1, ESeC parity.** Collapsing Macro-SEC must equal native
  `isco88_to_esec()`/`isco08_to_esec()` on every comparable cell: 2,531 and
  2,930, **0 disagreements**. Genuinely external, since the two are
  independently sourced.
- **D2, nesting.** micro, meso and Macro-SEC each determine ESeC on their own.
- micro-class unit-group detail survives; labels attach; case-function
  semantics; invalid codes and cases fail safe.

**If D1 or D2 move off zero, a change broke either ESeC parity or nesting.**
That is the signal to watch after any table edit.

### Running Stata here

Stata is **15**. Do-files run through the `stata-mcp` tool, which requires them
to sit under `~/Documents/.statamcp/stata-mcp-dofile` and refuses:

- `do `, `run `, or `mata` at the start of a line
- a line consisting only of a bare local
- `erase`, `copy`, or `net` as the command — prefixes like `quietly` are
  stripped before matching, so `quietly copy` is blocked too

That last one is why `test_installed.do` verifies the `.pkg` by comparing file
lists rather than building a fixture directory, and why the `net install` URL
had to be checked by fetching it rather than by running `net describe`.

## Design decisions worth not relitigating

- **No plain ESeC table.** crosswalk already ships `isco88_to_esec()` and
  `isco08_to_esec()`; duplicating them would risk the two falling out of step.
- **No `case.mcstatus5()`.** An earlier version shipped a second case function
  taking the source files' 1–5 status scale directly. It was removed to follow
  crosswalk's conventions: the add-on exposes only the standard 6-column case,
  built by `case.mcempstat()`. The source tables' 5-column shape is an
  implementation detail, not part of the interface.
- **Column 1 is `.` in every table.** MSEC has no simplified variant for
  unknown employment status, and crosswalk sends observations with a missing or
  out-of-range case to column 1. Coding it missing is what makes those
  observations come back uncoded instead of silently picking up another class.
- **`mc.` prefix syntax** is what makes crosswalk pick up the `labels_mc_*`
  label sets rather than same-named labels from crosswalk or another add-on.
- **Two different "micro" schemes** ship here and confusing them gives wrong
  answers: `micro` (Micro-SEC, 30, jointly assigned with employment relation) and
  `microclass` (77, ISCO-08 only, purely occupational). Both the README and the
  help file carry an explicit warning.
