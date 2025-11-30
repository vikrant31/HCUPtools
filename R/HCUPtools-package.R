#' HCUPtools: Access and Work with HCUP Resources and Datasets
#'
#' @description
#' `HCUPtools` is a comprehensive R package for accessing and working with 
#' publicly available resources from the Agency for Healthcare Research and 
#' Quality (AHRQ) Healthcare Cost and Utilization Project (HCUP). The package 
#' provides streamlined access to HCUP's Clinical Classifications Software 
#' Refined (CCSR) mapping files and Summary Trend Tables, enabling researchers 
#' and analysts to efficiently map ICD-10 codes to CCSR categories and access 
#' HCUP statistical reports.
#'
#' @details
#' The package provides functions to:
#' \itemize{
#' \item Download CCSR mapping files directly from the HCUP website
#' \item Map ICD-10-CM diagnosis codes and ICD-10-PCS procedure codes to CCSR categories
#' \item Access CCSR category descriptions and metadata
#' \item Download HCUP Summary Trend Tables
#' \item Read downloaded files from disk (ZIP, CSV, Excel, or directories)
#' \item Manage multiple CCSR versions and change logs
#' \item Generate proper AHRQ/HCUP citations
#' }
#'
#' The package does **not** redistribute CCSR data files but facilitates 
#' direct download from the official AHRQ HCUP website, ensuring users 
#' always have access to the latest versions and maintain compliance with 
#' HCUP data use policies.
#' 
#' **Important:** This package only accesses publicly available and free HCUP 
#' resources (CCSR tools and Summary Trend Tables). It does NOT access any 
#' HCUP databases (NIS, KID, SID, NEDS, etc.) that require purchase through 
#' the HCUP Central Distributor.
#'
#' For more information about CCSR, see the 
#' [official HCUP CCSR overview page](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp).
#'
#' @section Main Functions:
#' 
#' **CCSR Mapping Functions:**
#' \itemize{
#' \item `download_ccsr()` - Download CCSR mapping files from HCUP website
#' \item `read_ccsr()` - Read CCSR mapping files from disk (ZIP, CSV, Excel, or directory)
#' \item `ccsr_map()` - Map ICD-10 codes to CCSR categories (long/wide/default formats)
#' \item `get_ccsr_description()` - Get clinical descriptions for CCSR codes
#' \item `list_ccsr_versions()` - List available CCSR versions
#' \item `ccsr_changelog()` - Get CCSR change log for a specific version
#' }
#' 
#' **HCUP Summary Trend Tables Functions:**
#' \itemize{
#' \item `download_trend_tables()` - Download HCUP Summary Trend Tables
#' \item `read_trend_table()` - Read HCUP Summary Trend Table Excel files from disk
#' \item `list_trend_table_sheets()` - List available sheets in a trend table file
#' }
#' 
#' **Utility Functions:**
#' \itemize{
#' \item `hcup_citation()` - Generate citations for HCUP resources (CCSR or Trend Tables)
#' }
#'
#' @section Key Features:
#' \itemize{
#' \item **Direct Download**: Automatically download CCSR mapping files and Summary Trend Tables from HCUP
#' \item **Multiple Formats**: Support for long, wide, and default-only output formats
#' \item **Cross-Classification**: Handle one-to-many mappings (multiple CCSR categories per ICD-10 code)
#' \item **Version Management**: Access multiple CCSR versions and change logs
#' \item **Citation Generation**: Automatically generate proper AHRQ/HCUP citations
#' \item **File Reading**: Read downloaded files from disk (ZIP, CSV, Excel, or directories)
#' \item **Caching**: Intelligent caching to avoid redundant downloads
#' \item **Interactive Menus**: User-friendly interactive selection for files and options
#' }
#'
#' @section Legal and Usage:
#' **Important Disclaimer:** This package is an independent, non-commercial tool 
#' developed by a third party. It is **not affiliated with, endorsed by, or 
#' supported by AHRQ or HCUP in any way.** This package is not an official AHRQ 
#' or HCUP product. Users are responsible for ensuring compliance with all 
#' applicable HCUP Data Use Agreements (DUAs).
#'
#' **User Responsibilities:**
#' \itemize{
#' \item Understanding and complying with all applicable HCUP data usage policies
#' \item Verifying the accuracy of results
#' \item Citing the appropriate AHRQ/HCUP sources in publications
#' \item Ensuring compliance with all HCUP Data Use Agreements
#' }
#'
#' For official HCUP information and policies, visit:
#' \itemize{
#' \item [HCUP Data Use Agreement Training](https://hcup-us.ahrq.gov/tech_assist/dua.jsp)
#' \item [HCUP Data Use Agreements](https://hcup-us.ahrq.gov/team/NationwideDUA.pdf)
#' \item [HCUP Publishing Requirements](https://hcup-us.ahrq.gov/db/publishing.jsp)
#' \item [CCSR Overview](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp)
#' \item [HCUP Summary Trend Tables](https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp)
#' }
#'
#' @section Technical Details:
#' \itemize{
#' \item **Encoding**: Files are read with UTF-8 encoding to handle special characters
#' \item **Leading Zeros**: ICD-10 codes are preserved as character strings
#' \item **Caching**: Downloaded files are cached by default to avoid redundant downloads
#' \item **Cross-Classification**: Handles one-to-many mappings (multiple CCSR categories per ICD-10 code)
#' \item **Version Management**: Automatic detection of latest versions and support for historical versions
#' }
#'
#' @seealso
#' Useful links:
#' \itemize{
#' \item \url{https://github.com/vikrant31/HCUPtools} - Package GitHub repository
#' \item \url{https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp} - CCSR Overview
#' \item \url{https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp} - CCSR Tools and Downloads
#' \item \url{https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp} - Summary Trend Tables
#' \item \url{https://hcup-us.ahrq.gov/} - HCUP Homepage
#' }
#'
#' @author
#' **Maintainer:** Vikrant Dev Rathore \email{rathore.vikrant@gmail.com}
#'
#' @keywords internal
"_PACKAGE"
