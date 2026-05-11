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
#> Using cached file: /tmp/Rtmpjir88H/HCUP_SummaryTrendTables_T2a.xlsx
list_trend_table_sheets(path_xlsx)
#>  [1] "DUA"                        "HCUP"                      
#>  [3] "Methods"                    "Coding_Priority_Conditions"
#>  [5] "Coding_Encounter_Type"      "Coding_Deliveries"         
#>  [7] "Coding_Service_Line"        "National"                  
#>  [9] "Northeast"                  "Midwest"                   
#> [11] "South"                      "West"                      
#> [13] "Alaska"                     "Arizona"                   
#> [15] "Arkansas"                   "California"                
#> [17] "Colorado"                   "Connecticut"               
#> [19] "Delaware"                   "District of Columbia"      
#> [21] "Florida"                    "Georgia"                   
#> [23] "Hawaii"                     "Illinois"                  
#> [25] "Indiana"                    "Iowa"                      
#> [27] "Kansas"                     "Kentucky"                  
#> [29] "Louisiana"                  "Maine"                     
#> [31] "Maryland"                   "Massachusetts"             
#> [33] "Michigan"                   "Minnesota"                 
#> [35] "Mississippi"                "Missouri"                  
#> [37] "Montana"                    "Nebraska"                  
#> [39] "Nevada"                     "New Jersey"                
#> [41] "New Mexico"                 "New York"                  
#> [43] "North Carolina"             "North Dakota"              
#> [45] "Ohio"                       "Oklahoma"                  
#> [47] "Oregon"                     "Pennsylvania"              
#> [49] "Rhode Island"               "South Carolina"            
#> [51] "South Dakota"               "Tennessee"                 
#> [53] "Texas"                      "Utah"                      
#> [55] "Vermont"                    "Virginia"                  
#> [57] "Washington"                 "West Virginia"             
#> [59] "Wisconsin"                  "Wyoming"                   
# }
```
