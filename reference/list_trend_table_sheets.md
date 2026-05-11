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
# Requires network: download first, then list sheets from that file path
path_xlsx <- download_trend_tables("2a")
#> Warning: Could not fetch trend tables from HCUP website: Failed to perform HTTP request.
#> Caused by error in `curl::curl_fetch_memory()`:
#> ! Timeout was reached [hcup-us.ahrq.gov]:
#> Connection timed out after 30002 milliseconds. Using fallback method.
#> Error in download_trend_tables("2a"): Invalid table_id. Use download_trend_tables() to see available tables.
list_trend_table_sheets(path_xlsx)
#> Error: object 'path_xlsx' not found
# }
```
