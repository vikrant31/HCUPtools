# Read HCUP Summary Trend Table from Disk

Reads a previously downloaded HCUP Summary Trend Table Excel file from
disk. If no file path is provided, automatically finds and reads cached
files from
[`download_trend_tables()`](https://vikrant31.github.io/HCUPtools/reference/download_trend_tables.md),
with an interactive menu to select from available tables.

## Usage

``` r
read_trend_table(
  file_path = NULL,
  table_id = NULL,
  sheet = NULL,
  clean_names = TRUE,
  as_data_table = NULL,
  name = NULL
)
```

## Arguments

- file_path:

  Optional character string, path to a trend table Excel file (.xlsx).
  If NULL (default), automatically searches the cache directory for
  files downloaded via
  [`download_trend_tables()`](https://vikrant31.github.io/HCUPtools/reference/download_trend_tables.md)
  and shows an interactive menu.

- table_id:

  Optional character string, table ID (e.g., "1", "2a", "2b") to read
  from cache. Only used when `file_path` is NULL. If both are NULL,
  shows interactive menu.

- sheet:

  Character string or integer specifying which sheet to read. If NULL
  (default), shows an interactive menu to select a sheet (in interactive
  sessions), or automatically selects the "National" sheet (or first
  data sheet) in non-interactive sessions. Common sheet names include
  "National", "Regional", "State", etc.

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
  result: `my_data <- read_trend_table()`. If NULL (default), a name is
  suggested based on the table ID and sheet.

## Value

A tibble (or data.table if `as_data_table = TRUE`) containing the trend
table data. Tibbles are data frames and can be used with all standard R
data frame operations, including `dplyr`, `data.table`, and base R
functions.

## Details

HCUP Summary Trend Tables are Excel files with multiple sheets
containing data at different geographic levels (National, Regional,
State). Use the `sheet` parameter to specify which sheet to read, or
call the function multiple times with different sheets.

When `file_path` is NULL, the function automatically searches the cache
directory ([`tempdir()`](https://rdrr.io/r/base/tempfile.html)) for
files matching the pattern `HCUP_SummaryTrendTables_*.xlsx`. If multiple
files are found, an interactive menu is displayed for selection.

To see available sheets, use
[`list_trend_table_sheets()`](https://vikrant31.github.io/HCUPtools/reference/list_trend_table_sheets.md).

## Note

To use the data, assign it to a variable:
`my_data <- read_trend_table()`. The `name` parameter is only for
display purposes and does not automatically assign the data.

## Examples

``` r
# \donttest{
# Requires network: download a table, list sheets, read data (same file path)
path_xlsx <- download_trend_tables("2a")
#> Warning: Could not fetch trend tables from HCUP website: Failed to perform HTTP request.
#> Caused by error in `curl::curl_fetch_memory()`:
#> ! Timeout was reached [hcup-us.ahrq.gov]:
#> Connection timed out after 30001 milliseconds. Using fallback method.
#> Error in download_trend_tables("2a"): Invalid table_id. Use download_trend_tables() to see available tables.
list_trend_table_sheets(path_xlsx)
#> Error: object 'path_xlsx' not found
national_data <- read_trend_table(file_path = path_xlsx, as_data_table = FALSE)
#> Error: object 'path_xlsx' not found
head(national_data)
#> Error: object 'national_data' not found

# After a download, you can also read from cache by table ID
table_2a <- read_trend_table(table_id = "2a", as_data_table = FALSE)
#> Error in read_trend_table(table_id = "2a", as_data_table = FALSE): No cached trend table files found. Please download a file first using `download_trend_tables()` or provide a `file_path`.
head(table_2a)
#> Error: object 'table_2a' not found

# With a file already on disk, pass its path to `read_trend_table(file_path = ...)`.
# }
```
