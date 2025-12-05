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
# Automatically read from cache (shows menu if multiple files)
# Assign to a variable to use the data
national_data <- read_trend_table()
#> Reading cached file: HCUP_SummaryTrendTables_T2a.xlsx
#> Reading sheet: National
#> New names:
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`

# Read specific table from cache with suggested name
table_2a <- read_trend_table(table_id = "2a", name = "table_2a")
#> Reading cached file: HCUP_SummaryTrendTables_T2a.xlsx
#> Reading sheet: National
#> New names:
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`

# Read from a specific file path (manual)
national_data <- read_trend_table("path/to/HCUP_SummaryTrendTables_T2a.xlsx")
#> Error in read_trend_table("path/to/HCUP_SummaryTrendTables_T2a.xlsx"): File not found: path/to/HCUP_SummaryTrendTables_T2a.xlsx

# Read a specific sheet with custom name
state_data <- read_trend_table(
  "path/to/HCUP_SummaryTrendTables_T2a.xlsx",
  sheet = "State",
  name = "state_data"
)
#> Error in read_trend_table("path/to/HCUP_SummaryTrendTables_T2a.xlsx",     sheet = "State", name = "state_data"): File not found: path/to/HCUP_SummaryTrendTables_T2a.xlsx

# List available sheets first
sheets <- list_trend_table_sheets("path/to/HCUP_SummaryTrendTables_T2a.xlsx")
#> Error in list_trend_table_sheets("path/to/HCUP_SummaryTrendTables_T2a.xlsx"): File not found: path/to/HCUP_SummaryTrendTables_T2a.xlsx
print(sheets)
#> Error: object 'sheets' not found

# Use the data after assignment
head(national_data)
#> # A tibble: 6 × 25
#>   hcup_summary_trend_tab…¹ `2`   `3`   `4`   `5`   `6`   `7`   `8`   `9`   `10` 
#>   <chr>                    <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#> 1 National - Table 2a. Al… NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> 2 Asterisks (***) indicat… NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> 3 Counts less than or equ… NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> 4 Source: Agency for Heal… NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> 5 Characteristic by Quart… 2017… 2017… 2017… 2017… 2018… 2018… 2018… 2018… 2019…
#> 6 Number of Discharges fo… NA    NA    NA    NA    NA    NA    NA    NA    NA   
#> # ℹ abbreviated name: ¹​hcup_summary_trend_tables
#> # ℹ 15 more variables: `11` <chr>, `12` <chr>, `13` <chr>, `14` <chr>,
#> #   `15` <chr>, `16` <chr>, `17` <chr>, `18` <chr>, `19` <chr>, `20` <chr>,
#> #   `21` <chr>, `22` <chr>, `23` <chr>, `24` <chr>, `25` <chr>
nrow(national_data)
#> [1] 139
# }
```
