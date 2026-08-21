# crosswalk_multiclass

Stata crosswalk tables translating **ISCO-88com** and **ISCO-08** occupational
codes into the class schemes of the **Multilevel Socio-Economic Class** (MSEC) schema. This is a nested set of schemas
with a micro, meso and macro implementation which are modular and reduce to the well known ESEC schema (Harrison and Rose, 2006)
All MSEC crosswalks are implemented at the level of minor ISCO groups (3 digit). 

| scheme | classes | destination | available for |
|---|---|---|---|
| Micro-SEC | 30 | `micro` | ISCO-88com, ISCO-08 |
| Meso-SEC | 18 | `meso` | ISCO-88com, ISCO-08 |
| Macro-SEC | 11 | `macro` | ISCO-88com, ISCO-08 |

The add-on also provides a translation from ISCO-08 to **microclass** with 77 categories.
It is an ISCO-08 implementation of Jonsson et al. (2009) ISCO-88 crosswalk. The microclass scheme is not nested into ESEC or part of the MSEC. It is included here to facilitate replication of Hertel, Barone and Smallenbroek (2025).


This is an **add-on for the [`crosswalk`](https://github.com/benjann/crosswalk)
package** by Ben Jann. Like
[`kldbrecode`](https://github.com/hagerhardt/kldbrecode), it contains **no
`.ado` file** — it is pure crosswalk data, and all recoding is done by the
`crosswalk` command.

## Requirements

- Stata 14 or newer
- [`crosswalk`](https://github.com/benjann/crosswalk) — `ssc install crosswalk, replace`
- [`moremata`](http://fmwww.bc.edu/RePEc/bocode/m) 2.0.0 or newer — `ssc install moremata, replace`

## Install

From SSC, once the package is accepted:

```stata
ssc install crosswalk_multiclass, replace
```

Directly from GitHub:

```stata
net install crosswalk_multiclass, from("https://raw.githubusercontent.com/OscarSmallenbroek/crosswalk_multiclass/master/multiclass-addon") replace
```

Then:

```stata
help crosswalk_multiclass
```

## Usage

The tables use crosswalk's **prefix syntax** — `mc.`*origin*`_to_`*scheme*`()`.
The `mc.` prefix is what makes crosswalk pick up this package's class labels.

Micro-SEC, Meso-SEC and Macro-SEC are defined jointly over occupation and
employment relation, so they take a `case` argument built by
`case.mcempstat()` from a self-employment indicator and a supervisory or
employee-count variable:

```stata
crosswalk micro  = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))
crosswalk macro = mc.isco88com_to_macro(isco88 case.mcempstat(selfemp nsuperv))
```

3-digit data works directly, without the 4-digit wrapper:

```stata
crosswalk meso = mc.isco08_3_to_meso(isco08_3digit case.mcempstat(selfemp nsuperv))
```

The 77-category micro-class scheme is purely occupational and takes **no case
argument**:

```stata
crosswalk microclass = mc.isco08_to_microclass(isco08)
```

## Employment status

The case follows the same convention as the ESeC tables that ship with
`crosswalk`:

| case | meaning |
|---|---|
| 1 | employment status unknown |
| 2 | employed, without supervisory status |
| 3 | employed, with supervisory status |
| 4 | self-employed, no employees |
| 5 | self-employed, 1–9 employees |
| 6 | self-employed, 10 or more employees |


Unlike ESEC, **Column 1 is missing in every table.** The Multilevel Socio-Economic Classes schemes have no simplified variant for
unknown employment status, so observations whose employment status is unknown
come back uncoded rather than silently picking up another class.

## Where is ESeC?

`crosswalk` already ships `isco88_to_esec()` and `isco08_to_esec()` for plain 9-class ESeC —
use those:

```stata
crosswalk esec = isco08_to_esec(isco08 case.esec(selfemp nsuperv))
```
 Macro-SEC is ESEC + separating professionals from managers in ESEC classes I and II.

## Sources

**Macro-SEC** was introduced in Smallenbroek, Hertel and Barone, (2022). 

**Macro-SEC and Micro-SEC** were assessed alongside other class schemes in Hertel, Barone and Smallenbroek (2025).
Note that the Micro-SEC assessed in Hertel et al. (2025) is an **earlier
prototype**, whose development is documented at in Smallenbroek, Hertel and Barone (2023).
It is *not* the version of Micro-SEC shipped here. The paper documenting the
version implemented in this package is under review.

**The 77-category micro-class scheme** is documented in Smallenbroek, Hertel and Barone (2026).
It follows the micro-class approach of Grusky, Weeden and Sorensen (2000) and
Weeden and Grusky (2005), emulating the categories of Jonsson et al. (2009).

## References

Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
Approaches to Class Analysis. *European Societies* 1–65.
[doi:10.1162/euso_a_00044](https://doi.org/10.1162/euso_a_00044).

Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class Hierarchies in
Postindustrial Societies: A Criterion and Construct Validation of EGP and ESEC
Across 31 Countries. *Sociological Methods & Research* 53(3):1412–52.
[doi:10.1177/00491241221134522](https://doi.org/10.1177/00491241221134522).

Smallenbroek O, Hertel FR, Barone C. 2023. The Micro Socio-Economic Class scheme. 
[osf.io/preprints/socarxiv/962q3_v1](https://osf.io/preprints/socarxiv/962q3_v1)

Smallenbroek, O., F. R. Hertel, C. Barone. 2026. Adapting the Microclass Schema
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

Oscar Smallenbroek.

## Contributing

Development notes, the build chain and the test suite are documented in
[`dev/DEVELOPMENT.md`](dev/DEVELOPMENT.md).
