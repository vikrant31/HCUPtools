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
if (FALSE) { # \dontrun{
# Text citation for CCSR
hcup_citation()

# BibTeX format for CCSR
hcup_citation(format = "bibtex")

# Citation for Summary Trend Tables
hcup_citation(resource = "trend_tables")

# R citation object
hcup_citation(format = "r")
} # }
```
