# List Available CCSR Versions

Returns a list of available CCSR versions for download by scraping the
HCUP website. This function helps users identify which versions are
available for diagnosis and procedure mapping files.

## Usage

``` r
list_ccsr_versions(type = "all")
```

## Arguments

- type:

  Character string specifying the type of CCSR file. Must be one of:
  "diagnosis" (or "dx"), "procedure" (or "pr"), or "all" (default) to
  list versions for both types.

## Value

A data frame (tibble) with columns:

- `type`: The CCSR type ("diagnosis" or "procedure")

- `version`: The version identifier (e.g., "v2026.1")

## Details

This function fetches available CCSR versions from the HCUP website.
Results are cached for 24 hours to minimize website requests. If the
website cannot be accessed, the function will return an error.

## Examples

``` r
# \donttest{
# List all available versions
list_ccsr_versions()
#> Error in list_ccsr_versions(): Could not retrieve CCSR versions from HCUP website. Please check your internet connection and try again.

# List only diagnosis versions
list_ccsr_versions("diagnosis")
#> Error in list_ccsr_versions("diagnosis"): Could not retrieve CCSR versions from HCUP website. Please check your internet connection and try again.

# List only procedure versions
list_ccsr_versions("procedure")
#> Error in list_ccsr_versions("procedure"): Could not retrieve CCSR versions from HCUP website. Please check your internet connection and try again.
# }
```
