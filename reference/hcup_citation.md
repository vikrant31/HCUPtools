# Generate Citation for HCUP Resources

Provides recommended citations for HCUP resources including Clinical
Classifications Software Refined (CCSR) data and Summary Trend Tables
from the Agency for Healthcare Research and Quality (AHRQ) Healthcare
Cost and Utilization Project (HCUP).

## Usage

``` r
hcup_citation(format = "text", version = "latest", resource = "ccsr")
```

## Arguments

- format:

  Character string specifying the citation format. Must be one of:
  "text" (default), "bibtex", or "r" (for R citation object).

- version:

  Character string specifying the CCSR version to cite. If "latest"
  (default), the function will attempt to fetch the latest version from
  the HCUP website. Otherwise, specify a version like "v2026.1".

- resource:

  Character string specifying which HCUP resource to cite. Options:
  "ccsr" (default) for CCSR data, or "trend_tables" for Summary Trend
  Tables.

## Value

If `format` is "text", returns a character string with the citation. If
`format` is "bibtex", returns a character string with BibTeX format. If
`format` is "r", returns an R citation object.

## Details

This function generates citations for HCUP resources following AHRQ/HCUP
guidelines. The citation includes the appropriate version number and
access date. For CCSR data, the version is automatically detected if not
specified. For Summary Trend Tables, the citation references the general
HCUP Summary Trend Tables resource.

## Examples

``` r
# Text citation for CCSR
hcup_citation()
#> [1] "Agency for Healthcare Research and Quality. Clinical Classifications Software Refined (CCSR) for ICD-10-CM Diagnoses, v2026.1. Healthcare Cost and Utilization Project (HCUP). Agency for Healthcare Research and Quality, Rockville, MD. www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp. Accessed December 16, 2025. "

# BibTeX format for CCSR
hcup_citation(format = "bibtex")
#> [1] "@misc{hcup_ccsr_20261,\n  title = {Clinical Classifications Software Refined (CCSR) for ICD-10-CM Diagnoses, v2026.1},\n  author = {{Agency for Healthcare Research and Quality}},\n  organization = {Healthcare Cost and Utilization Project (HCUP)},\n  publisher = {Agency for Healthcare Research and Quality},\n  address = {Rockville, MD},\n  year = {2026},\n  url = {https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp},\n  note = {Accessed December 16, 2025}\n}"

# Citation for Summary Trend Tables
hcup_citation(resource = "trend_tables")
#> [1] "Agency for Healthcare Research and Quality. HCUP Summary Trend Tables. Healthcare Cost and Utilization Project (HCUP). Agency for Healthcare Research and Quality, Rockville, MD. www.hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp. Accessed December 16, 2025. "

# R citation object
hcup_citation(format = "r")
#> Agency for Healthcare Research and Quality (2026). “Clinical
#> Classifications Software Refined (CCSR) for ICD-10-CM Diagnoses,
#> v2026.1.” Accessed December 16, 2025,
#> <https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp>.
```
