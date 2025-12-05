# Download CCSR Mapping Files from HCUP

Downloads and loads Clinical Classifications Software Refined (CCSR)
mapping files directly from the Agency for Healthcare Research and
Quality (AHRQ) Healthcare Cost and Utilization Project (HCUP) website.

## Usage

``` r
download_ccsr(
  type = "diagnosis",
  version = "latest",
  cache = TRUE,
  clean_names = TRUE
)
```

## Arguments

- type:

  Character string specifying the type of CCSR file to download. Must be
  one of: "diagnosis" (or "dx") for ICD-10-CM diagnosis codes, or
  "procedure" (or "pr") for ICD-10-PCS procedure codes. Default is
  "diagnosis".

- version:

  Character string specifying the CCSR version to download. Use "latest"
  to download the most recent version, or specify a version like
  "v2026.1", "v2025.1", etc. Default is "latest".

- cache:

  Logical. If TRUE (default), the downloaded file is cached in a
  temporary directory to avoid re-downloading on subsequent calls.

- clean_names:

  Logical. If TRUE (default), column names are cleaned to follow R
  naming conventions (snake_case).

## Value

A tibble containing the CCSR mapping data with the following columns:

- For diagnosis files: ICD-10-CM code, CCSR category, default CCSR
  category, and clinical descriptions

- For procedure files: ICD-10-PCS code, CCSR category, and descriptions

## Details

This function downloads CCSR mapping files directly from the HCUP
website. The package does not redistribute these files but facilitates
access to the official AHRQ data sources.

The function handles:

- Automatic URL construction based on type and version

- ZIP file download and extraction

- Proper encoding of special characters

- Preservation of leading zeros in ICD-10 codes

- Conversion to tidy tibble format

## Examples

``` r
# \donttest{
# Download latest diagnosis CCSR mapping
dx_map <- download_ccsr("diagnosis")
#> Using cached file: /tmp/Rtmp6OONtw/HCUPtools_cache/DXCCSR-v2026-1.zip
#> Reading mapping file: DXCCSR_v2026-1.csv

# Download specific version of procedure CCSR mapping
pr_map <- download_ccsr("procedure", version = "v2025.1")
#> Downloading from: https://hcup-us.ahrq.gov/toolssoftware/ccsr/PRCCSR_v2025-1.zip
#> Download complete: /tmp/Rtmp6OONtw/HCUPtools_cache/PRCCSR_v2025-1.zip
#> Reading mapping file: PRCCSR_v2025-1.csv

# Download without caching
dx_map <- download_ccsr("diagnosis", cache = FALSE)
#> Downloading from: https://hcup-us.ahrq.gov/toolssoftware/ccsr/DXCCSR-v2026-1.zip
#> Download complete: /tmp/Rtmp6OONtw/file185c14d33ce.zip
#> Reading mapping file: DXCCSR_v2026-1.csv
# }
```
