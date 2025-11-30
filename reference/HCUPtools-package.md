# HCUPtools: Access and Work with HCUP Resources and Datasets

`HCUPtools` is a comprehensive R package for accessing and working with
publicly available resources from the Agency for Healthcare Research and
Quality (AHRQ) Healthcare Cost and Utilization Project (HCUP). The
package provides streamlined access to HCUP's Clinical Classifications
Software Refined (CCSR) mapping files and Summary Trend Tables, enabling
researchers and analysts to efficiently map ICD-10 codes to CCSR
categories and access HCUP statistical reports.

## Details

The package provides functions to:

- Download CCSR mapping files directly from the HCUP website

- Map ICD-10-CM diagnosis codes and ICD-10-PCS procedure codes to CCSR
  categories

- Access CCSR category descriptions and metadata

- Download HCUP Summary Trend Tables

- Read downloaded files from disk (ZIP, CSV, Excel, or directories)

- Manage multiple CCSR versions and change logs

- Generate proper AHRQ/HCUP citations

The package does **not** redistribute CCSR data files but facilitates
direct download from the official AHRQ HCUP website, ensuring users
always have access to the latest versions and maintain compliance with
HCUP data use policies.

**Important:** This package only accesses publicly available and free
HCUP resources (CCSR tools and Summary Trend Tables). It does NOT access
any HCUP databases (NIS, KID, SID, NEDS, etc.) that require purchase
through the HCUP Central Distributor.

For more information about CCSR, see the [official HCUP CCSR overview
page](https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp).

## Main Functions

**CCSR Mapping Functions:**

- [`download_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/download_ccsr.md) -
  Download CCSR mapping files from HCUP website

- [`read_ccsr()`](https://vikrant31.github.io/HCUPtools/reference/read_ccsr.md) -
  Read CCSR mapping files from disk (ZIP, CSV, Excel, or directory)

- [`ccsr_map()`](https://vikrant31.github.io/HCUPtools/reference/ccsr_map.md) -
  Map ICD-10 codes to CCSR categories (long/wide/default formats)

- [`get_ccsr_description()`](https://vikrant31.github.io/HCUPtools/reference/get_ccsr_description.md) -
  Get clinical descriptions for CCSR codes

- [`list_ccsr_versions()`](https://vikrant31.github.io/HCUPtools/reference/list_ccsr_versions.md) -
  List available CCSR versions

- [`ccsr_changelog()`](https://vikrant31.github.io/HCUPtools/reference/ccsr_changelog.md) -
  Get CCSR change log for a specific version

**HCUP Summary Trend Tables Functions:**

- [`download_trend_tables()`](https://vikrant31.github.io/HCUPtools/reference/download_trend_tables.md) -
  Download HCUP Summary Trend Tables

- [`read_trend_table()`](https://vikrant31.github.io/HCUPtools/reference/read_trend_table.md) -
  Read HCUP Summary Trend Table Excel files from disk

- [`list_trend_table_sheets()`](https://vikrant31.github.io/HCUPtools/reference/list_trend_table_sheets.md) -
  List available sheets in a trend table file

**Utility Functions:**

- [`hcup_citation()`](https://vikrant31.github.io/HCUPtools/reference/hcup_citation.md) -
  Generate citations for HCUP resources (CCSR or Trend Tables)

## Key Features

- **Direct Download**: Automatically download CCSR mapping files and
  Summary Trend Tables from HCUP

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

- **Interactive Menus**: User-friendly interactive selection for files
  and options

## Legal and Usage

**Important Disclaimer:** This package is an independent, non-commercial
tool developed by a third party. It is **not affiliated with, endorsed
by, or supported by AHRQ or HCUP in any way.** This package is not an
official AHRQ or HCUP product. Users are responsible for ensuring
compliance with all applicable HCUP Data Use Agreements (DUAs).

**User Responsibilities:**

- Understanding and complying with all applicable HCUP data usage
  policies

- Verifying the accuracy of results

- Citing the appropriate AHRQ/HCUP sources in publications

- Ensuring compliance with all HCUP Data Use Agreements

For official HCUP information and policies, visit:

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

## Technical Details

- **Encoding**: Files are read with UTF-8 encoding to handle special
  characters

- **Leading Zeros**: ICD-10 codes are preserved as character strings

- **Caching**: Downloaded files are cached by default to avoid redundant
  downloads

- **Cross-Classification**: Handles one-to-many mappings (multiple CCSR
  categories per ICD-10 code)

- **Version Management**: Automatic detection of latest versions and
  support for historical versions

## See also

Useful links:

- <https://github.com/vikrant31/HCUPtools> - Package GitHub repository

- <https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp> - CCSR
  Overview

- <https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp> - CCSR
  Tools and Downloads

- <https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp> -
  Summary Trend Tables

- <https://hcup-us.ahrq.gov/> - HCUP Homepage

## Author

**Maintainer:** Vikrant Dev Rathore <rathore.vikrant@gmail.com>
