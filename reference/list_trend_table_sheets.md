# List Available Sheets in Trend Table

Lists all available sheets in a HCUP Summary Trend Table Excel file.

## Usage

``` r
list_trend_table_sheets(file_path)
```

## Arguments

- file_path:

  Character string, path to a trend table Excel file (.xlsx).

## Value

A character vector of sheet names.

## Examples

``` r
# \donttest{
sheets <- list_trend_table_sheets("path/to/HCUP_SummaryTrendTables_T2a.xlsx")
#> Error in list_trend_table_sheets("path/to/HCUP_SummaryTrendTables_T2a.xlsx"): File not found: path/to/HCUP_SummaryTrendTables_T2a.xlsx
print(sheets)
#> Error: object 'sheets' not found
# }
```
