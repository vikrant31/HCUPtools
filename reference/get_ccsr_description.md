# Get CCSR Category Descriptions

Retrieves the full clinical description for one or more CCSR category
codes. This function helps users interpret CCSR codes by providing their
meaningful clinical descriptions.

## Usage

``` r
get_ccsr_description(ccsr_codes, map_df = NULL, type = NULL)
```

## Arguments

- ccsr_codes:

  Character vector of CCSR category codes (e.g., "ADM010", "NEP003",
  "CIR019").

- map_df:

  Optional. A tibble containing CCSR mapping data with descriptions. If
  provided, descriptions are extracted from this data frame. If NULL
  (default), the function will attempt to download the latest mapping
  file to extract descriptions.

- type:

  Character string specifying the type of CCSR codes. Must be one of:
  "diagnosis" (or "dx") or "procedure" (or "pr"). If NULL (default), the
  function will attempt to infer the type from the codes or mapping
  data.

## Value

A tibble with columns:

- `ccsr_code`: The CCSR category code

- `description`: The full clinical description

- Additional metadata columns if available in the mapping data

## Details

CCSR category codes follow specific naming conventions:

- Diagnosis codes: Typically start with letters (e.g., "ADM010",
  "NEP003")

- Procedure codes: Typically start with letters (e.g., "PRC001",
  "PRC002")

If a description is not found for a code, it will be marked as NA in the
result.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get descriptions using downloaded mapping data
dx_map <- download_ccsr("diagnosis")
get_ccsr_description(c("ADM010", "NEP003", "CIR019"), map_df = dx_map)

# Get descriptions without pre-downloaded data (will download automatically)
get_ccsr_description(c("ADM010", "NEP003"), type = "diagnosis")
} # }
```
