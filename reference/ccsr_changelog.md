# Get CCSR Change Log

Retrieves and displays the change log for CCSR versions. The change log
documents updates, additions, and modifications to CCSR categories
across different versions.

## Usage

``` r
ccsr_changelog(
  version = "latest",
  type = "diagnosis",
  format = "read",
  as_data_table = NULL
)
```

## Arguments

- version:

  Character string specifying the CCSR version. Use "latest" (default)
  to get the change log for the most recent version, or specify a
  version like "v2026.1", "v2025.1", etc.

- type:

  Character string specifying the type of CCSR. Must be one of:
  "diagnosis" (or "dx") for ICD-10-CM diagnosis codes, or "procedure"
  (or "pr") for ICD-10-PCS procedure codes. Default is "diagnosis".

- format:

  Character string specifying the output format. Options: "read"
  (default) - Downloads and reads the Excel file as a data table/tibble
  (requires `readxl` package) "text" - Returns change log information as
  text "url" - Returns the URL to the change log document "download" -
  Downloads and returns the change log file path "view" - Downloads and
  opens the change log file in the default viewer "extract" - Attempts
  to extract text from the file (requires `pdftools` for PDF or `readxl`
  for Excel)

- as_data_table:

  Logical. If TRUE, returns a `data.table` instead of a tibble. Only
  used when `format = "read"`. If NULL (default), prompts the user
  interactively to choose (only in interactive sessions). In
  non-interactive sessions, defaults to FALSE.

## Value

Depending on `format`:

- "read" (default): A tibble or data.table containing the change log
  data (if Excel file)

- "text": Character string with change log information

- "url": Character string with URL to change log

- "download": Character string with path to downloaded file

- "view": Opens the file and returns the file path (invisibly)

- "extract": Character string with extracted text from file

## Details

CCSR change logs document:

- New CCSR categories added

- Categories that were removed or merged

- Changes to category descriptions

- Updates to ICD-10 code mappings

- Version-specific notes and improvements

Change logs are typically available as PDF or text documents on the HCUP
website. This function attempts to locate and retrieve them.

## Examples

``` r
# \donttest{
# Get latest change log URL
changelog_url <- ccsr_changelog(format = "url")

# Get change log information
changelog_info <- ccsr_changelog(version = "v2026.1", format = "text")

# Download change log file
changelog_file <- ccsr_changelog(version = "v2025.1", format = "download")
#> Change log downloaded to: /tmp/Rtmp6OONtw/HCUPtools_cache/DXCCSR-ChangeLog-v20241-v20251.xlsx

# View change log in default PDF viewer
ccsr_changelog(version = "v2026.1", format = "view")
#> Change log downloaded to: /tmp/Rtmp6OONtw/HCUPtools_cache/DXCCSR-ChangeLog-v20251-v20261.xlsx
#> Change log Excel file opened in default application

# Extract text from change log PDF (requires pdftools package)
changelog_text <- ccsr_changelog(version = "v2026.1", format = "extract")
#> Using cached change log: /tmp/Rtmp6OONtw/HCUPtools_cache/DXCCSR-ChangeLog-v20251-v20261.xlsx
#> Content extracted from change log Excel file (8 sheet(s))
cat(changelog_text)
#> 
#> === Sheet: Table_of_Contents ===
#> 
#> # A tibble: 12 × 1
#>    This Excel file enumerates the changes between the following releases of th…¹
#>    <chr>                                                                        
#>  1 Compared versions: v2026.1 (released October 2025) to v2025.1 (released Nove…
#>  2 Table of Contents                                                            
#>  3 Changes to the CCSR category                                                 
#>  4 List of new CCSR categories                                                  
#>  5 List of redefined or discontinued CCSR categories                            
#>  6 List of CCSR categories that have modifications to the category description  
#>  7 Changes to the mapping of ICD-10-CM diagnosis codes to CCSR category         
#>  8 List of ICD-10-CM diagnosis codes that are mapped into a different CCSR cate…
#>  9 List of ICD-10-CM diagnosis codes for which the default CCSR category for th…
#> 10 List of ICD-10-CM diagnosis codes for which the default CCSR category for th…
#> 11 List of ICD-10-CM diagnosis codes that were added to the CCSR tool           
#> 12 End of Content                                                               
#> # ℹ abbreviated name:
#> #   ¹​`This Excel file enumerates the changes between the following releases of the Clinical Classifications Software Refined (CCSR) for ICD-10-CM diagnoses`
#> 
#> === Sheet: New_CCSR_category ===
#> 
#> # A tibble: 3 × 2
#>   `List of new CCSR categories (v2026.1 vs v2025.1)` ``                         
#>   <chr>                                              <chr>                      
#> 1 CCSR Category                                      CCSR Category Description …
#> 2 SYM019                                             Flank pain and tenderness  
#> 3 End of Content                                     NA                         
#> 
#> === Sheet: Changed_CCSR_category ===
#> 
#> # A tibble: 3 × 2
#>   `List of redefined or discontinued CCSR categories (v2026.1 vs v2025.1)` ``   
#>   <chr>                                                                    <chr>
#> 1 CCSR Category                                                            CCSR…
#> 2 NA                                                                       No C…
#> 3 End of Content                                                           NA   
#> 
#> === Sheet: Change_to_CCSR_description ===
#> 
#> # A tibble: 3 × 3
#>   List of CCSR categories that have modifications to the category …¹ ``    ``   
#>   <chr>                                                              <chr> <chr>
#> 1 CCSR Category                                                      Chan… CCSR…
#> 2 NA                                                                 NA    No m…
#> 3 End of Content                                                     NA    NA   
#> # ℹ abbreviated name:
#> #   ¹​`List of CCSR categories that have modifications to the category description (v2026.1 vs v2025.1)`
#> 
#> === Sheet: Change_DX_to_CCSR_mapping ===
#> 
#> # A tibble: 15 × 6
#>    List of ICD-10-CM diagnosis codes that are ma…¹ ``    ``    ``    ``    ``   
#>    <chr>                                           <chr> <chr> <chr> <chr> <chr>
#>  1 List is sorted by ICD-10-CM diagnosis code, bu… NA    NA    NA    NA    NA   
#>  2 CCSR Category                                   CCSR… ICD-… ICD-… In v… In v…
#>  3 INF002                                          Sept… A393  Chro… Dele… INF0…
#>  4 INF002                                          Sept… B007  Diss… Dele… INF0…
#>  5 INF003                                          Bact… I76   Sept… INF0… INF0…
#>  6 INF003                                          Bact… I2601 Sept… INF0… NA   
#>  7 INF003                                          Bact… I2690 Sept… INF0… NA   
#>  8 INF003                                          Bact… O8681 Puer… INF0… NA   
#>  9 INF003                                          Bact… O883… Pyem… INF0… NA   
#> 10 INF003                                          Bact… O883… Pyem… INF0… NA   
#> 11 INF003                                          Bact… O883… Pyem… INF0… NA   
#> 12 INF003                                          Bact… O883… Pyem… INF0… NA   
#> 13 INF003                                          Bact… O8832 Pyem… INF0… NA   
#> 14 INF003                                          Bact… O8833 Pyem… INF0… NA   
#> 15 End of Content                                  NA    NA    NA    NA    NA   
#> # ℹ abbreviated name:
#> #   ¹​`List of ICD-10-CM diagnosis codes that are mapped into a different CCSR category (v2026.1 vs v2025.1)`
#> 
#> === Sheet: Change_to_IPdefault_CCSR ===
#> 
#> # A tibble: 5 × 6
#>   List of ICD-10-CM diagnosis codes for which th…¹ ``    ``    ``    ``    ``   
#>   <chr>                                            <chr> <chr> <chr> <chr> <chr>
#> 1 List is sorted by ICD-10-CM diagnosis code, but… NA    NA    NA    NA    NA   
#> 2 ICD-10-CM Code                                   ICD-… Inpa… Inpa… Inpa… Inpa…
#> 3 A393                                             Chro… INF0… Bact… INF0… Sept…
#> 4 B007                                             Diss… INF0… Vira… INF0… Sept…
#> 5 End of Content                                   NA    NA    NA    NA    NA   
#> # ℹ abbreviated name:
#> #   ¹​`List of ICD-10-CM diagnosis codes for which the default CCSR category for the inpatient principal diagnosis changed (v2026.1 vs v2025.1)`
#> 
#> === Sheet: Change_to_OPdefault_CCSR ===
#> 
#> # A tibble: 6 × 6
#>   List of ICD-10-CM diagnosis codes for which th…¹ ``    ``    ``    ``    ``   
#>   <chr>                                            <chr> <chr> <chr> <chr> <chr>
#> 1 List is sorted by ICD-10-CM diagnosis code, but… NA    NA    NA    NA    NA   
#> 2 ICD-10-CM Code                                   ICD-… Outp… Outp… Outp… Outp…
#> 3 A393                                             Chro… INF0… Bact… INF0… Sept…
#> 4 B007                                             Diss… INF0… Vira… INF0… Sept…
#> 5 I76                                              Sept… CIR0… Aort… INF0… Sept…
#> 6 End of Content                                   NA    NA    NA    NA    NA   
#> # ℹ abbreviated name:
#> #   ¹​`List of ICD-10-CM diagnosis codes for which the default CCSR category for the outpatient first-listed diagnosis changed (v2026.1 vs v2025.1)`
#> 
#> === Sheet: Added_diagnosis_codes ===
#> 
#> # A tibble: 489 × 18
#>    List of ICD-10-CM dia…¹ ``    ``    ``    ``    ``    ``    ``    ``    ``   
#>    <chr>                   <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>
#>  1 Added ICD-10-CM Diagno… ICD-… Inpa… Inpa… Outp… Outp… CCSR… CCSR… CCSR… CCSR…
#>  2 B8801                   Infe… SKN0… Othe… SKN0… Othe… SKN0… Othe… INF0… Para…
#>  3 B8809                   Othe… SKN0… Othe… SKN0… Othe… SKN0… Othe… INF0… Para…
#>  4 C50A0                   Mali… NEO0… Brea… NEO0… Brea… NEO0… Brea… NA    NA   
#>  5 C50A1                   Mali… NEO0… Brea… NEO0… Brea… NEO0… Brea… NA    NA   
#>  6 C50A2                   Mali… NEO0… Brea… NEO0… Brea… NEO0… Brea… NA    NA   
#>  7 D711                    Leuk… BLD0… Dise… BLD0… Dise… BLD0… Dise… NA    NA   
#>  8 D718                    Othe… BLD0… Dise… BLD0… Dise… BLD0… Dise… NA    NA   
#>  9 D719                    Func… BLD0… Dise… BLD0… Dise… BLD0… Dise… NA    NA   
#> 10 E11A                    Type… END0… Diab… END0… Diab… END0… Diab… END0… Diab…
#> # ℹ 479 more rows
#> # ℹ abbreviated name:
#> #   ¹​`List of ICD-10-CM diagnosis codes that were added to the CCSR tool (v2026.1 vs v2025.1)`
#> # ℹ 8 more variables: `` <chr>, `` <chr>, `` <chr>, `` <chr>, `` <chr>,
#> #   `` <chr>, `` <chr>, `` <chr>
# }
```
