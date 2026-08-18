# crosswalk_multiclass

Stata crosswalk tables translating **ISCO-88com** and **ISCO-08** occupational
codes into the class schemes of the **MultiClass** schema. This is a nested set of schemas
with a micro, meso and macro implementation which are modular and reduce to the well known ESEC schema (Harrison and Rose, 2006)
All Multiclass crosswalks are implemented for 3-digit ISCO codes. 

| scheme | classes | destination | available for |
|---|---|---|---|
| MicroSEC | 30 | `micro` | ISCO-88com, ISCO-08 |
| meso-class | 18 | `meso` | ISCO-88com, ISCO-08 |
| ESeC-MP | 11 | `esecmp` | ISCO-88com, ISCO-08 |

The add-on also provides a translation from ISCO-08 to microclass as developed by Grusky, Weeden and Sorensen (2000), which is not nested into ESEC or part of the Multiclass schema. 

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

MicroSEC, MesoSEC and ESeC-MP are defined jointly over occupation and
employment relation, so they take a `case` argument built by
`case.mcempstat()` from a self-employment indicator and a supervisory or
employee-count variable:

```stata
crosswalk micro  = mc.isco08_to_micro(isco08 case.mcempstat(selfemp nsuperv))
crosswalk esecmp = mc.isco88com_to_esecmp(isco88 case.mcempstat(selfemp nsuperv))
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


Unlike ESEC, **Column 1 is missing in every table.** MultiClass has no simplified variant for
unknown employment status, so observations whose employment status is unknown
come back uncoded rather than silently picking up another class.

## Where is ESeC?

`crosswalk` already ships `isco88_to_esec()` and `isco08_to_esec()` for plain 9-class ESeC —
use those:

```stata
crosswalk esec = isco08_to_esec(isco08 case.esec(selfemp nsuperv))
```
`mc.<origin>_to_esecmp()` aggregates to the same ESeC classes with the rule
{1,2}→1, {3,4}→2, 5→3, 6→4, 7→5, 8→6, 9→7, 10→8, 11→9, and reproduces
crosswalk's own ESeC tables exactly.

## References

**ESeC-MP** was introduced in:

> Smallenbroek, O., F. R. Hertel, C. Barone. 2022. Measuring Class Hierarchies
> in Postindustrial Societies: A Criterion and Construct Validation of EGP and
> ESEC Across 31 Countries. *Sociological Methods & Research* 53(3):1412–52.
> [doi:10.1177/00491241221134522](https://doi.org/10.1177/00491241221134522)

**ESeC-MP and MicroSEC** were assessed alongside other class schemes in:

> Hertel, F. R., C. Barone, O. Smallenbroek. 2025. The Multiverse of Social
> Class. A Large-Scale Assessment of Macro-Level, Meso-Level and Micro-Level
> Approaches to Class Analysis. *European Societies* 1–65.
> [doi:10.1162/euso_a_00044](https://doi.org/10.1162/euso_a_00044)

Note that the MicroSEC assessed in Hertel et al. (2025) is an **earlier
prototype**, whose development is documented at
[osf.io/preprints/socarxiv/962q3_v1](https://osf.io/preprints/socarxiv/962q3_v1).
It is *not* the version of MicroSEC shipped here. The paper documenting the
version implemented in this package is under review.

**The 77-category micro-class scheme** is documented in:

> Smallenbroek, O., F. R. Hertel, C. Barone. n.d. Adapting the Microclass
> Schema for Cross-national Research.
> [osf.io/preprints/socarxiv/xaqju_v1](https://osf.io/preprints/socarxiv/xaqju_v1)

It follows the micro-class approach of Grusky, Weeden and Sorensen (2000) and
Weeden and Grusky (2005), emulating the categories of Jonsson et al. (2009).

For **ESeC** itself see Harrison and Rose (2006), *The European Socio-economic
Classification (ESeC) User Guide*, University of Essex. For the `crosswalk`
command see Jann, B. 2025, Statistical Software Components S459534.

Full citations are in `help crosswalk_multiclass`.

## Author

Oscar Smallenbroek.

The `crosswalk` command this package extends is by Ben Jann.

Jann, B. 2025. crosswalk: Stata module to recode variable based on
    crosswalk table (bulk recoding). Available from
    "https://ideas.repec.org/c/boc/bocode/s459420.html".

## Contributing

Development notes, the build chain and the test suite are documented in
[`dev/DEVELOPMENT.md`](dev/DEVELOPMENT.md).
