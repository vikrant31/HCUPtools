# HCUPtools: Access and Work with HCUP Resources

[![CRAN
status](https://www.r-pkg.org/badges/version/HCUPtools)](https://CRAN.R-project.org/package=HCUPtools)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**HCUPtools** is a comprehensive R package for accessing and working
with publicly available resources from the **Agency for Healthcare
Research and Quality (AHRQ) Healthcare Cost and Utilization Project
(HCUP)**. The package provides streamlined access to HCUP’s Clinical
Classifications Software Refined (CCSR) mapping files and Summary Trend
Tables, enabling researchers and analysts to efficiently map ICD-10
codes to CCSR categories and access HCUP statistical reports.

**Important Disclaimer:** This package is an independent, non-commercial
tool developed by a third party. It is **not affiliated with, endorsed
by, or supported by AHRQ or HCUP** in any way. This package is not an
official AHRQ or HCUP product.

## Overview

`HCUPtools` facilitates access to **free, publicly available** HCUP
resources, including:

- **CCSR Mapping Files**: Clinical Classifications Software Refined
  (CCSR) for ICD-10-CM diagnosis codes and ICD-10-PCS procedure codes
- **HCUP Summary Trend Tables**: Aggregated statistical reports on
  hospital utilization trends

The package does **not** redistribute HCUP data files but facilitates
direct download from the official AHRQ HCUP website, ensuring users
always have access to the latest versions and maintain compliance with
HCUP data use policies.

### Key Features

- **Direct Download**: Automatically download CCSR mapping files and
  Summary Trend Tables from HCUP
- **ICD-10 Mapping**: Map ICD-10-CM diagnosis codes and ICD-10-PCS
  procedure codes to CCSR categories
- **Multiple Formats**: Support for long, wide, and default-only output
  formats
- **Cross-Classification**: Handle one-to-many mappings (multiple CCSR
  categories per ICD-10 code)
- **Version Management**: Access multiple CCSR versions and change logs
- **Citation Generation**: Automatically generate proper AHRQ/HCUP
  citations
- **File Reading**: Read downloaded files from disk (ZIP, CSV, Excel, or
  directories)
- **Caching**: Intelligent caching to avoid redundant downloads

## Installation

``` r
# Install from CRAN
install.packages("HCUPtools")

# Load the package
library(HCUPtools)
```

## Quick Start

### Basic Workflow

``` r
# 1. Download the latest diagnosis CCSR mapping file
dx_map <- download_ccsr("diagnosis")

# 2. Create sample patient data with ICD-10 codes
sample_data <- tibble::tibble(
  patient_id = 1:5,
  admission_date = as.Date(c("2024-01-15", "2024-02-20", "2024-03-10", 
                              "2024-04-05", "2024-05-12")),
  icd10_code = c("E11.9", "I10", "M79.3", "E78.5", "K21.9")
)

# 3. Map ICD-10 codes to CCSR categories
mapped_data <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map
)

# 4. Get CCSR category descriptions
descriptions <- get_ccsr_description(
  c("ADM010", "NEP003", "CIR019"), 
  map_df = dx_map
)

# 5. Generate proper citation
hcup_citation()
```

## Comprehensive Usage Examples

### 1. Downloading CCSR Mapping Files

``` r
# Download latest version (recommended)
dx_map <- download_ccsr("diagnosis")
pr_map <- download_ccsr("procedure")

# Download specific version
dx_map_v2025 <- download_ccsr("diagnosis", version = "v2025.1")

# List all available versions
all_versions <- list_ccsr_versions()
print(all_versions)

# List versions for specific type
dx_versions <- list_ccsr_versions("diagnosis")
pr_versions <- list_ccsr_versions("procedure")
```

### 2. Mapping ICD-10 Codes to CCSR Categories

The
[`ccsr_map()`](https://vikrant31.github.io/HCUPtools/reference/ccsr_map.md)
function supports three output formats to accommodate different
analytical needs:

#### Long Format (Default)

Best for cross-classification analysis where you need to count all
assigned CCSR categories:

``` r
# Long format - duplicates records for each CCSR category
mapped_long <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map,
  output_format = "long"  # default
)

# Result: One row per ICD-10 code per CCSR category
# Useful for: Counting occurrences of each CCSR category
```

#### Wide Format

Best for patient-level analysis where you want all categories in one
row:

``` r
# Wide format - multiple CCSR columns
mapped_wide <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map,
  output_format = "wide"
)

# Result: One row per ICD-10 code with columns CCSR_1, CCSR_2, etc.
# Useful for: Patient-level analysis, keeping all categories together
```

#### Default Category Only

Best for principal diagnosis analysis:

``` r
# Default category only (diagnosis codes only)
mapped_default <- ccsr_map(
  data = sample_data,
  code_col = "icd10_code",
  map_df = dx_map,
  default_only = TRUE
)

# Result: One row per ICD-10 code with only the default CCSR category
# Useful for: Principal diagnosis analysis, following HCUP recommendations
```

### 3. Working with Procedure Codes

``` r
# Download procedure mapping
pr_map <- download_ccsr("procedure")

# Create sample procedure data
procedure_data <- tibble::tibble(
  case_id = 1:3,
  icd10_pcs = c("0DB60ZZ", "0DT70ZZ", "0WQ3XZ")
)

# Map procedure codes
mapped_procedures <- ccsr_map(
  data = procedure_data,
  code_col = "icd10_pcs",
  map_df = pr_map
)
```

### 4. Accessing CCSR Descriptions

``` r
# Get descriptions for specific CCSR codes
ccsr_codes <- c("ADM010", "NEP003", "CIR019", "END001")
descriptions <- get_ccsr_description(ccsr_codes, map_df = dx_map)
print(descriptions)

# Auto-download if mapping not provided
descriptions_auto <- get_ccsr_description(
  c("ADM010", "NEP003"), 
  type = "diagnosis"
)
```

### 5. Downloading HCUP Summary Trend Tables

``` r
# List all available tables (interactive menu)
available_tables <- download_trend_tables()

# Download a specific table by ID
table_path <- download_trend_tables("2a")  # All inpatient discharges

# Download all tables as ZIP file (~81 MB)
all_tables <- download_trend_tables("all")
```

### 6. Reading Downloaded Files

If you’ve already downloaded files, read them directly:

``` r
# Read CCSR file from various formats
dx_map <- read_ccsr("path/to/DXCCSR-v2026-1.zip")
dx_map <- read_ccsr("path/to/DXCCSR_v2026-1.csv")
dx_map <- read_ccsr("path/to/DXCCSR_v2026-1.xlsx")
dx_map <- read_ccsr("path/to/extracted_directory/")

# Read trend table Excel file
national_data <- read_trend_table(
  "path/to/HCUP_SummaryTrendTables_T2a.xlsx",
  sheet = "National"
)

# List available sheets
sheets <- list_trend_table_sheets(
  "path/to/HCUP_SummaryTrendTables_T2a.xlsx"
)

# Read specific state data
state_data <- read_trend_table(
  "path/to/HCUP_SummaryTrendTables_T2a.xlsx",
  sheet = "California"
)
```

### 7. Viewing CCSR Change Logs

``` r
# Get change log as data table (default)
changelog <- ccsr_changelog(version = "v2026.1")
print(changelog)

# Get change log URL
changelog_url <- ccsr_changelog(version = "v2026.1", format = "url")

# View change log in default PDF viewer
ccsr_changelog(version = "v2026.1", format = "view")

# Download change log file
changelog_file <- ccsr_changelog(version = "v2026.1", format = "download")
```

### 8. Generating Citations

Always cite HCUP data properly in publications:

``` r
# Text citation for CCSR
cat(hcup_citation())

# Citation for Summary Trend Tables
cat(hcup_citation(resource = "trend_tables"))

# BibTeX format (for LaTeX documents)
cat(hcup_citation(format = "bibtex"))

# R citation object (for R markdown)
citation_obj <- hcup_citation(format = "r")
print(citation_obj)
```

## Complete Function Reference

| Function                                                                                                  | Description                                                       |
|-----------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| [`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md)                     | Download CCSR mapping files from HCUP website                     |
| [`read_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/read_ccsr.md)                             | Read CCSR mapping files from disk (ZIP, CSV, Excel, or directory) |
| [`ccsr_map()`](https://vikrant31.github.io/HCUPtools/reference/ccsr_map.md)                               | Map ICD-10 codes to CCSR categories (long/wide/default formats)   |
| [`get_ccsr_description()`](https://vikrant31.github.io/HCUPtools/reference/get_ccsr_description.md)       | Get clinical descriptions for CCSR codes                          |
| [`list_ccsr_versions()`](https://vikrant31.github.io/HCUPtools/reference/list_ccsr_versions.md)           | List available CCSR versions                                      |
| [`ccsr_changelog()`](https://vikrant31.github.io/HCUPtools/reference/ccsr_changelog.md)                   | Get CCSR change log for a specific version                        |
| [`download_trend_tables()`](https://vikrant31.github.io/HCUPtools/reference/download_trend_tables.md)     | Download HCUP Summary Trend Tables                                |
| [`read_trend_table()`](https://vikrant31.github.io/HCUPtools/reference/read_trend_table.md)               | Read HCUP Summary Trend Table Excel files from disk               |
| [`list_trend_table_sheets()`](https://vikrant31.github.io/HCUPtools/reference/list_trend_table_sheets.md) | List available sheets in a trend table file                       |
| [`hcup_citation()`](https://vikrant31.github.io/HCUPtools/reference/hcup_citation.md)                     | Generate citations for HCUP resources (CCSR or Trend Tables)      |

## Important Legal and Compliance Information

### Data Usage Compliance

This package facilitates access to **publicly available and free** HCUP
resources:

- **CCSR Mapping Files** - Classification software tools (free download
  from [HCUP Tools &
  Software](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr.jsp))
- **HCUP Summary Trend Tables** - Aggregated statistical reports (free
  download from [HCUP
  Reports](https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp))

**Critical:** This package does **NOT** access any HCUP databases (NIS,
KID, SID, NEDS, etc.) that require purchase through the [HCUP Central
Distributor](https://hcup-us.ahrq.gov/tech_assist/centdist.jsp). All
resources accessed by this package are freely available public tools and
reports.

### User Responsibilities

Users are responsible for:

- Understanding and complying with all applicable AHRQ/HCUP data usage
  policies and restrictions
- Verifying the accuracy of results
- Citing the appropriate AHRQ/HCUP sources in publications
- Ensuring compliance with all HCUP Data Use Agreements (DUAs)

### Essential Resources

- [HCUP Data Use Agreement (DUA)
  Training](https://hcup-us.ahrq.gov/tech_assist/dua.jsp)
- [HCUP Data Use
  Agreements](https://hcup-us.ahrq.gov/team/NationwideDUA.pdf)
- [HCUP Publishing
  Requirements](https://hcup-us.ahrq.gov/db/publishing.jsp)
- [CCSR
  Overview](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp)
- [HCUP Summary Trend
  Tables](https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp)
- [HCUP Tools and
  Software](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp)

### Disclaimer

**This package is an independent, non-commercial tool developed by a
third party.** It is **not affiliated with, endorsed by, or supported by
AHRQ or HCUP in any way.** This package is not an official AHRQ or HCUP
product. The developers of this package have no relationship with AHRQ
or HCUP.

This package is provided “as is” without warranty of any kind. Users are
solely responsible for verifying the accuracy of results and ensuring
compliance with all applicable HCUP data use policies.

For official HCUP information, visit: <https://hcup-us.ahrq.gov/>

## Technical Details

### Dependencies

**Core Dependencies:** - `httr2`: HTTP requests for downloading files
from HCUP website - `readr`: Reading CSV files with proper encoding -
`dplyr`: Data manipulation and joins - `tidyr`: Data reshaping
(long/wide formats) - `tibble`: Modern data frame format - `rlang`:
Advanced R programming utilities - `xml2`: HTML/XML parsing for web
scraping

**Optional Dependencies:** - `readxl`: Reading Excel files (for trend
tables) - `data.table`: High-performance data operations (optional) -
`pdftools`: PDF text extraction (for change logs)

### Data Handling Features

- **Encoding**: Files are read with UTF-8 encoding to handle special
  characters correctly
- **Leading Zeros**: ICD-10 codes are preserved as character strings to
  maintain leading zeros (e.g., “E11.9” not “E11.9”)
- **Caching**: Downloaded files are cached by default to avoid redundant
  network requests
- **Cross-Classification**: The package handles one-to-many mappings
  (multiple CCSR categories per ICD-10 code)
- **Version Management**: Automatic detection of latest versions and
  support for historical versions

### Performance Considerations

- **Caching**: First download requires internet connection; subsequent
  calls use cached files
- **Large Files**: CCSR mapping files are ~75,000 rows; Summary Trend
  Tables can be large Excel files
- **Memory**: All data is loaded into memory as tibbles; consider
  `data.table` option for very large datasets

## Citation

If you use this package in your research, please cite both the package
and the HCUP data:

``` r
# Package citation
citation("HCUPtools")

# CCSR data citation (automatically formatted)
hcup_citation()

# Summary Trend Tables citation
hcup_citation(resource = "trend_tables")
```

## Contributing

Contributions are welcome! Please feel free to:

- Submit issues and bug reports
- Propose new features
- Submit pull requests
- Improve documentation

## Acknowledgments

- **AHRQ/HCUP**: For providing the CCSR classification tool and making
  it publicly available
- **R Community**: For the excellent tools and packages that make this
  work possible

## Contact

- **Package Maintainer**: Vikrant Dev Rathore
- **Email**: <rathore.vikrant@gmail.com>
- **GitHub**:
  [vikrant31/HCUPtools](https://github.com/vikrant31/HCUPtools)
- **Issues**: [GitHub
  Issues](https://github.com/vikrant31/HCUPtools/issues)

------------------------------------------------------------------------

**Note**: This package is under active development. Features and
function signatures may change in future versions. For the most
up-to-date information, please visit the [GitHub
repository](https://github.com/vikrant31/HCUPtools).
