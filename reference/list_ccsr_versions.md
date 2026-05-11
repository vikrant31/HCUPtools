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
#> # A tibble: 11 × 2
#>    type      version
#>    <chr>     <chr>  
#>  1 diagnosis v2025.1
#>  2 procedure v2025.1
#>  3 diagnosis v2024.1
#>  4 procedure v2024.1
#>  5 diagnosis v2023.1
#>  6 procedure v2023.1
#>  7 diagnosis v2022.1
#>  8 procedure v2022.1
#>  9 diagnosis v2021.2
#> 10 diagnosis v2021.1
#> 11 procedure v2021.1

# List only diagnosis versions
list_ccsr_versions("diagnosis")
#> # A tibble: 6 × 2
#>   type      version
#>   <chr>     <chr>  
#> 1 diagnosis v2025.1
#> 2 diagnosis v2024.1
#> 3 diagnosis v2023.1
#> 4 diagnosis v2022.1
#> 5 diagnosis v2021.2
#> 6 diagnosis v2021.1

# List only procedure versions
list_ccsr_versions("procedure")
#> # A tibble: 5 × 2
#>   type      version
#>   <chr>     <chr>  
#> 1 procedure v2025.1
#> 2 procedure v2024.1
#> 3 procedure v2023.1
#> 4 procedure v2022.1
#> 5 procedure v2021.1
# }
```
