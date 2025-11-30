# Getting Started with HCUPtools

`HCUPtools` is an R package for accessing and working with resources
from the **Agency for Healthcare Research and Quality (AHRQ) Healthcare
Cost and Utilization Project (HCUP)**. This vignette provides a
comprehensive guide to using the package for common healthcare data
analysis tasks.

## Installation and Setup

``` r
# Install from CRAN
install.packages("HCUPtools")

# Load the package
library(HCUPtools)
library(dplyr)  # For data manipulation examples
```

## Part 1: Downloading CCSR Mapping Files

The Clinical Classifications Software Refined (CCSR) is a tool developed
by AHRQ/HCUP to categorize ICD-10-CM diagnosis codes and ICD-10-PCS
procedure codes into clinically meaningful categories. The
[`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md)
function provides direct access to these mapping files.

### Download Latest Version

``` r
# Download the latest diagnosis CCSR mapping file
dx_map <- download_ccsr("diagnosis")

# Download the latest procedure CCSR mapping file
pr_map <- download_ccsr("procedure")
```

### Download Specific Version

``` r
# Download a specific version (useful for reproducibility)
dx_map_v2025 <- download_ccsr("diagnosis", version = "v2025.1")
pr_map_v2025 <- download_ccsr("procedure", version = "v2025.1")
```

### List Available Versions

``` r
# List all available versions
all_versions <- list_ccsr_versions()
print(all_versions)

# List only diagnosis versions
dx_versions <- list_ccsr_versions("diagnosis")

# List only procedure versions
pr_versions <- list_ccsr_versions("procedure")
```

## Part 2: Mapping ICD-10 Codes to CCSR Categories

Once you have downloaded a mapping file, you can use
[`ccsr_map()`](https://vikrant31.github.io/HCUPtools/reference/ccsr_map.md)
to map ICD-10 codes to CCSR categories. This function supports multiple
output formats to accommodate different analytical needs.

### Prepare Sample Data

``` r
# Create sample patient data with ICD-10 diagnosis codes
patient_data <- tibble::tibble(
  patient_id = 1:10,
  admission_date = as.Date(c("2024-01-15", "2024-02-20", "2024-03-10", 
                              "2024-04-05", "2024-05-12", "2024-06-18",
                              "2024-07-22", "2024-08-30", "2024-09-14",
                              "2024-10-08")),
  icd10_dx = c("E11.9", "I10", "M79.3", "E78.5", "K21.9", 
               "I50.9", "N18.6", "E78.5", "I25.10", "J44.1")
)
```

### Long Format (Default)

The long format duplicates records for each assigned CCSR category. This
is essential for cross-classification analysis where you need to count
all assigned categories.

``` r
# Map codes using long format (default)
mapped_long <- ccsr_map(
  data = patient_data,
  code_col = "icd10_dx",
  map_df = dx_map,
  output_format = "long"
)

# View the results
head(mapped_long, 20)

# Count occurrences of each CCSR category
ccsr_counts <- mapped_long |>
  count(ccsr_category, sort = TRUE)
print(ccsr_counts)
```

**Use Case**: Long format is ideal when you want to: - Count how many
times each CCSR category appears - Analyze cross-classifications (one
ICD-10 code mapping to multiple CCSR categories) - Create frequency
tables of CCSR categories

### Wide Format

The wide format creates multiple columns (CCSR_1, CCSR_2, etc.) for
multiple categories, keeping one row per ICD-10 code.

``` r
# Map codes using wide format
mapped_wide <- ccsr_map(
  data = patient_data,
  code_col = "icd10_dx",
  map_df = dx_map,
  output_format = "wide"
)

# View the results
head(mapped_wide)
```

**Use Case**: Wide format is ideal when you want to: - Keep all CCSR
categories for each patient in a single row - Perform patient-level
analysis - Maintain the original data structure with additional CCSR
columns

### Default Category Only

For diagnosis codes, CCSR assigns a “default” category that is
recommended for principal diagnosis analysis. Use `default_only = TRUE`
to extract only this default category.

``` r
# Map codes using default category only
mapped_default <- ccsr_map(
  data = patient_data,
  code_col = "icd10_dx",
  map_df = dx_map,
  default_only = TRUE
)

# View the results
head(mapped_default)
```

**Use Case**: Default category is ideal when you want to: - Analyze
principal diagnoses only - Follow HCUP recommendations for diagnosis
analysis - Maintain one-to-one mapping (one ICD-10 code = one CCSR
category)

## Part 3: Getting CCSR Descriptions

To understand what CCSR categories mean, use
[`get_ccsr_description()`](https://vikrant31.github.io/HCUPtools/reference/get_ccsr_description.md):

``` r
# Get descriptions for specific CCSR codes
ccsr_codes <- c("ADM010", "NEP003", "CIR019", "END001", "MBD001")
descriptions <- get_ccsr_description(ccsr_codes, map_df = dx_map)
print(descriptions)

# Get descriptions without pre-downloaded mapping (will download automatically)
descriptions_auto <- get_ccsr_description(
  c("ADM010", "NEP003"), 
  type = "diagnosis"
)
```

## Part 4: Working with Procedure Codes

The package also supports ICD-10-PCS procedure codes:

``` r
# Download procedure mapping
pr_map <- download_ccsr("procedure")

# Create sample procedure data
procedure_data <- tibble::tibble(
  case_id = 1:5,
  procedure_date = as.Date(c("2024-01-20", "2024-02-15", "2024-03-22",
                              "2024-04-10", "2024-05-18")),
  icd10_pcs = c("0DB60ZZ", "0DT70ZZ", "0WQ3XZ", "0FB00ZZ", "0HB00ZX")
)

# Map procedure codes
mapped_procedures <- ccsr_map(
  data = procedure_data,
  code_col = "icd10_pcs",
  map_df = pr_map
)

# View the results
head(mapped_procedures)
```

## Part 5: Complete Analysis Workflow

Here’s a complete workflow for analyzing CCSR categories in a dataset:

``` r
# Step 1: Download mapping file
dx_map <- download_ccsr("diagnosis")

# Step 2: Map diagnosis codes
patient_data_mapped <- ccsr_map(
  data = patient_data,
  code_col = "icd10_dx",
  map_df = dx_map,
  output_format = "long"
)

# Step 3: Count occurrences of each CCSR category
ccsr_counts <- patient_data_mapped |>
  count(ccsr_category, sort = TRUE)

# Step 4: Merge with descriptions for reporting
ccsr_counts_with_desc <- ccsr_counts |>
  left_join(
    get_ccsr_description(
      unique(patient_data_mapped$ccsr_category), 
      map_df = dx_map
    ),
    by = c("ccsr_category" = "ccsr_code")
  )

# Step 5: View the final results
print(ccsr_counts_with_desc)
```

## Part 6: Downloading HCUP Summary Trend Tables

The package also provides access to HCUP Summary Trend Tables, which
contain aggregated information on hospital utilization trends:

``` r
# List available tables (interactive menu)
available_tables <- download_trend_tables()
print(available_tables)

# Download a specific table by ID
# Table 2a: All Inpatient Encounter Types - Trends in Number of Discharges
table_path <- download_trend_tables("2a")

# Download all tables as a ZIP file (~81 MB)
all_tables_zip <- download_trend_tables("all")
```

The trend tables include: - Overview of trends in inpatient and
emergency department utilization - All inpatient encounter types
(discharges, percent, length of stay, mortality, population rates) -
Inpatient encounter types (normal newborns, deliveries,
elective/non-elective stays) - Inpatient service lines
(maternal/neonatal, mental health, injuries, surgeries, medical
conditions) - ED treat-and-release visits

For more information, see: [HCUP Summary Trend
Tables](https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp)

### Reading Trend Tables

``` r
# Read the trend table data
trend_data <- read_trend_table(table_path, sheet = "National")
head(trend_data)

# List available sheets
sheets <- list_trend_table_sheets(table_path)
print(sheets)

# Read specific state data
california_data <- read_trend_table(table_path, sheet = "California")
```

## Part 7: Accessing CCSR Change Logs

View changes between CCSR versions:

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

## Part 8: Generating Citations

When using HCUP data in publications, always cite the source properly:

``` r
# Generate text citation for CCSR
cat(hcup_citation())

# Generate citation for Summary Trend Tables
cat(hcup_citation(resource = "trend_tables"))

# Generate BibTeX citation (for LaTeX documents)
cat(hcup_citation(format = "bibtex"))

# Generate R citation object (for R markdown)
citation_obj <- hcup_citation(format = "r")
print(citation_obj)
```

## Part 9: Reading Downloaded Files

If you’ve already downloaded files, you can read them directly:

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
```

## Important Notes

### Data Download

- The package downloads data directly from HCUP, so an internet
  connection is required for the first download
- Downloaded files are cached by default to avoid re-downloading
- Set `cache = FALSE` to disable caching

### Cross-Classification

- One ICD-10 code can map to multiple CCSR categories
- Use long format to see all mappings
- Use default category for principal diagnosis analysis

### Default Categories

- For diagnosis codes, CCSR assigns a default category recommended for
  principal diagnosis analysis
- Use `default_only = TRUE` to extract only the default category

### Performance

- CCSR mapping files contain ~75,000 rows
- Consider using `as_data_table = TRUE` in
  [`read_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/read_ccsr.md)
  and
  [`read_trend_table()`](https://vikrant31.github.io/HCUPtools/reference/read_trend_table.md)
  for very large datasets

## Legal and Compliance

**Important Disclaimer:** This package is an independent, non-commercial
tool developed by a third party. It is **not affiliated with, endorsed
by, or supported by AHRQ or HCUP in any way.** This package is not an
official AHRQ or HCUP product.

This package facilitates access to **publicly available and free** HCUP
resources:

- **CCSR Mapping Files** - Classification software tools (free download)
- **HCUP Summary Trend Tables** - Aggregated statistical reports (free
  download)

**Critical:** This package does **NOT** access any HCUP databases (NIS,
KID, SID, NEDS, etc.) that require purchase through the HCUP Central
Distributor.

### User Responsibilities

Users are responsible for: - Ensuring compliance with all applicable
HCUP Data Use Agreements (DUAs) - Verifying the accuracy of results -
Citing the appropriate AHRQ/HCUP sources in publications - Understanding
and adhering to all HCUP data usage restrictions

### Essential Resources

- [HCUP Data Use Agreement
  Training](https://hcup-us.ahrq.gov/tech_assist/dua.jsp)
- [HCUP Data Use
  Agreements](https://hcup-us.ahrq.gov/team/NationwideDUA.pdf)
- [HCUP Publishing
  Requirements](https://hcup-us.ahrq.gov/db/publishing.jsp)
- [CCSR
  Overview](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp)
- [HCUP Summary Trend
  Tables](https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp)

## Additional Resources

- **Package GitHub**: <https://github.com/vikrant31/HCUPtools>
- **HCUP Homepage**: <https://hcup-us.ahrq.gov/>
- **CCSR Overview**:
  <https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp>
- **HCUP CCSR Tools**:
  <https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp>
- **HCUP Summary Trend Tables**:
  <https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp>
