# Read CCSR Mapping Files from Disk

Reads previously downloaded CCSR mapping files from disk. If no file
path is provided, automatically finds and reads cached files from
[`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md).

## Usage

``` r
read_ccsr(
  file_path = NULL,
  type = NULL,
  version = "latest",
  clean_names = TRUE,
  as_data_table = NULL,
  name = NULL
)
```

## Arguments

- file_path:

  Optional character string, path to a CCSR mapping file. Can be:

  - A ZIP file path (will be extracted and read)

  - A CSV/Excel file path (will be read directly)

  - A directory path containing extracted CCSR files If NULL (default),
    automatically searches the cache directory for files downloaded via
    [`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md).

- type:

  Character string specifying the type of CCSR file. Must be one of:
  "diagnosis" (or "dx") for ICD-10-CM diagnosis codes, or "procedure"
  (or "pr") for ICD-10-PCS procedure codes. If NULL and `file_path` is
  NULL, defaults to "diagnosis". If `file_path` is provided, the
  function will attempt to infer the type from the file name or
  contents.

- version:

  Character string specifying the CCSR version to read from cache. Use
  "latest" (default) to read the most recent version, or specify a
  version like "v2026.1", "v2025.1", etc. Only used when `file_path` is
  NULL.

- clean_names:

  Logical. If TRUE (default), column names are cleaned to follow R
  naming conventions (snake_case).

- as_data_table:

  Logical or NULL. If TRUE and the `data.table` package is available,
  returns a `data.table` object instead of a tibble. If FALSE, returns a
  tibble. If NULL (default), prompts the user interactively to choose
  (only in interactive sessions). In non-interactive sessions, defaults
  to FALSE. Note: tibbles are already data frames and work with all
  standard R data frame operations.

- name:

  Optional character string, suggested variable name for the returned
  data. This is only used for display/messaging purposes and does not
  automatically assign the data to a variable. You must still assign the
  result: `my_data <- read_ccsr()`. If NULL (default), a name is
  suggested based on the file type and version.

## Value

A tibble (or data.table if `as_data_table = TRUE`) containing the CCSR
mapping data. Tibbles are data frames and can be used with all standard
R data frame operations, including `dplyr`, `data.table`, and base R
functions.

## Details

This function can read CCSR files in several formats:

- ZIP files downloaded from HCUP (will extract and read the CSV/Excel
  file)

- CSV files (extracted from ZIP or saved separately)

- Excel files (if `readxl` package is available)

- Directories containing extracted files

- Cached files from
  [`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md)
  (automatic if `file_path` is NULL)

The function automatically detects the file format and handles encoding
issues, preserving leading zeros in ICD-10 codes.

When `file_path` is NULL, the function automatically searches the cache
directory (`tempdir()/HCUPtools_cache/`) for files matching the
specified `type` and `version`. This makes it easy to read previously
downloaded files without needing to know the exact file path.

## Note

To use the data, assign it to a variable: `my_data <- read_ccsr()`. The
`name` parameter is only for display purposes and does not automatically
assign the data.

## Examples

``` r
if (FALSE) { # \dontrun{
# Automatically read latest cached diagnosis file
# Assign to a variable to use the data
dx_map <- read_ccsr()

# Read specific version from cache with suggested name
dx_map_v2025 <- read_ccsr(type = "diagnosis", version = "v2025.1", name = "dx_map_v2025")

# Read procedure file from cache
pr_map <- read_ccsr(type = "procedure")

# Read from a specific file path (manual)
dx_map <- read_ccsr("path/to/DXCCSR-v2026-1.zip")

# Read from a CSV file
dx_map <- read_ccsr("path/to/DXCCSR_v2026_1.csv")

# Read from a directory
dx_map <- read_ccsr("path/to/extracted_ccsr_files/")

# Use the data after assignment
head(dx_map)
nrow(dx_map)
} # }
```
