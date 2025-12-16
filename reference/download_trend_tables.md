# Download HCUP Summary Trend Tables

Downloads HCUP Summary Trend Tables from the HCUP website. These tables
provide information on hospital utilization derived from HCUP databases,
including trends in inpatient and emergency department utilization.

## Usage

``` r
download_trend_tables(table_id = NULL, dest_dir = NULL, cache = TRUE)
```

## Arguments

- table_id:

  Character string or numeric specifying which table to download. Can
  be:

  - A table number (e.g., "1", "2a", "6b", "11c") for specific tables

  - "all" to download all available tables as a ZIP file

  - NULL (default) to show an interactive menu for selecting a table (in
    interactive sessions), or return a list of available tables (in
    non-interactive sessions)

- dest_dir:

  Character string specifying the destination directory for the
  downloaded file(s). If NULL (default), files are saved to a temporary
  directory.

- cache:

  Logical. If TRUE (default), downloaded files are cached to avoid
  re-downloading on subsequent calls.

## Value

If `table_id` is NULL and session is non-interactive, returns a data
frame listing available tables. Otherwise, returns the path(s) to the
downloaded file(s).

## Details

The HCUP Summary Trend Tables include information on:

- Overview of trends in inpatient and emergency department utilization

- All inpatient encounter types

- Inpatient encounter types (normal newborns, deliveries,
  elective/non-elective stays)

- Inpatient service lines (maternal/neonatal, mental health, injuries,
  surgeries, etc.)

- ED treat-and-release visits

Each table is available as an Excel file with state-specific,
region-specific, and national statistics.

The function automatically discovers available tables by scraping the
HCUP website, so it will automatically adapt to new tables or version
changes.

For more information, see:
https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp

## Examples

``` r
# \donttest{
# List available tables
available_tables <- download_trend_tables()
print(available_tables)
#> # A tibble: 49 × 3
#>    table_id table_name                                                 file_name
#>    <chr>    <chr>                                                      <chr>    
#>  1 1        Overview of Trends in Inpatient and Emergency Department … HCUP_Sum…
#>  2 2a       All Inpatient Encounter Types: Trends in the Number of Di… HCUP_Sum…
#>  3 2b       All Inpatient Encounter Types: Trends in the Percent of D… HCUP_Sum…
#>  4 2c       All Inpatient Encounter Types: Trends in the Average Leng… HCUP_Sum…
#>  5 2d       All Inpatient Encounter Types: Trends in the In-Hospital … HCUP_Sum…
#>  6 2e       All Inpatient Encounter Types: Trends in the Population R… HCUP_Sum…
#>  7 6a       Inpatient Encounter Type of Normal Newborns: Trends in th… HCUP_Sum…
#>  8 6b       Inpatient Encounter Type of Normal Newborns: Trends in th… HCUP_Sum…
#>  9 6c       Inpatient Encounter Type of Normal Newborns: Trends in th… HCUP_Sum…
#> 10 7a       Inpatient Encounter Type of Deliveries: Trends in the Num… HCUP_Sum…
#> # ℹ 39 more rows

# Download a specific table
table_path <- download_trend_tables("2a")
#> Downloading: All Inpatient Encounter Types: Trends in the Number of Discharges
#> URL: https://hcup-us.ahrq.gov/reports/trendtables/HCUP_SummaryTrendTables_T2a.xlsx
#> Download complete: /tmp/RtmpcIBM7b/HCUP_SummaryTrendTables_T2a.xlsx

# Download all tables
all_tables <- download_trend_tables("all")
#> Error in download_trend_tables("all"): The 'all tables' ZIP file is not available on the HCUP website. Please download individual tables using their table IDs. Use download_trend_tables() to see available tables.
# }
```
