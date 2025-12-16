# Map ICD-10 Codes to CCSR Categories

Maps ICD-10-CM diagnosis codes or ICD-10-PCS procedure codes to their
corresponding CCSR categories using a downloaded CCSR mapping file.

## Usage

``` r
ccsr_map(
  data,
  code_col,
  map_df,
  type = NULL,
  default_only = FALSE,
  output_format = "long",
  keep_all = TRUE
)
```

## Arguments

- data:

  A data frame or tibble containing ICD-10 codes to be mapped.

- code_col:

  Character string specifying the name of the column in `data` that
  contains the ICD-10 codes.

- map_df:

  A tibble containing the CCSR mapping data, typically obtained from
  [`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md).

- type:

  Character string specifying the type of mapping. Must be one of:
  "diagnosis" (or "dx") for ICD-10-CM codes, or "procedure" (or "pr")
  for ICD-10-PCS codes. If NULL (default), the function will attempt to
  infer the type from the mapping data frame.

- default_only:

  Logical. For diagnosis codes only, if TRUE, returns only the default
  CCSR category (recommended for principal diagnosis analysis). If FALSE
  (default), returns all assigned CCSR categories including
  cross-classifications.

- output_format:

  Character string specifying the output format. Must be one of: "long"
  (default) or "wide". "long" format duplicates records for each
  assigned CCSR category. "wide" format creates multiple columns
  (CCSR_1, CCSR_2, etc.) for multiple categories.

- keep_all:

  Logical. If TRUE (default), returns all original columns from `data`
  plus the CCSR mapping columns. If FALSE, returns only the ICD-10 code
  column and CCSR mapping columns.

## Value

A tibble with the original data plus CCSR mapping columns. The structure
depends on `output_format`:

- For "long" format: Each row represents one ICD-10 code and one CCSR
  category assignment (rows are duplicated for multiple categories).

- For "wide" format: Each row represents one ICD-10 code with multiple
  CCSR category columns (CCSR_1, CCSR_2, etc.).

## Details

CCSR allows for cross-classification, meaning a single ICD-10 code can
map to multiple CCSR categories. The "long" format is recommended for
analyses where you want to count all assigned CCSR categories, while
"wide" format may be more convenient for patient-level analyses.

For diagnosis codes, CCSR also assigns a "default" category that is
recommended for principal diagnosis analysis. Use `default_only = TRUE`
to extract only this default category.

## Examples

``` r
# \donttest{
# Download mapping file
dx_map <- download_ccsr("diagnosis")
#> Downloading from: https://hcup-us.ahrq.gov/toolssoftware/ccsr/DXCCSR-v2026-1.zip
#> Download complete: /tmp/RtmpcIBM7b/HCUPtools_cache/DXCCSR-v2026-1.zip
#> Reading mapping file: DXCCSR_v2026-1.csv

# Create sample data
sample_data <- tibble::tibble(
  patient_id = 1:3,
  icd10_code = c("E11.9", "I10", "M79.3")
)

# Map codes (long format - default)
mapped_long <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map
)

# Map codes (wide format)
mapped_wide <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map,
  output_format = "wide"
)

# Map codes (default category only)
mapped_default <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map,
  default_only = TRUE
)
# }
```
