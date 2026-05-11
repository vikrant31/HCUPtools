## Version 1.0.1 (2026-04-26)

### Bug fixes

- **`download_ccsr()` / `read_ccsr()`**: Strip surrounding quotes from character columns in HCUP CSVs so ICD and CCSR values join reliably.
- **`ccsr_map()`**: Diagnosis mapping now expands **CCSR Category 1–6** so cross-classifications appear in long and wide outputs; wide uses slot-aligned `CCSR_1`…`CCSR_6`; long diagnosis output includes **`is_default`**; fixed spurious wide column from unmatched rows.
- **`get_ccsr_description()`**: Normalize quoted CCSR codes when matching.
- **`list_ccsr_versions()`**: Merge scraped versions with direct file checks so current releases (e.g. v2026.1) appear.
- **`ccsr_changelog()`**: When `version` is explicit, skip interactive prompts for import format and sheet selection by default.
- **CRAN / `R CMD check`**: `inst/CITATION` now uses `bibentry()`; examples that require network, local files, or optional PDF tooling use `\donttest{}`; unused `pkgdown` removed from `Suggests`; non-package paths added to `.Rbuildignore`.

---

## Version 1.0.0 (2025-11-29)

### Features

#### CCSR Mapping Functions
- **`download_ccsr()`**: Download CCSR mapping files directly from HCUP website
  - Support for both diagnosis (ICD-10-CM) and procedure (ICD-10-PCS) mappings
  - Automatic version detection and "latest" version support
  - Intelligent caching to avoid redundant downloads
  - Proper encoding and leading zero preservation for ICD-10 codes

- **`read_ccsr()`**: Read CCSR mapping files from disk
  - Support for ZIP, CSV, Excel, and directory formats
  - Automatic cache discovery and interactive file selection
  - Optional data.table output for large datasets

- **`ccsr_map()`**: Map ICD-10 codes to CCSR categories
  - Multiple output formats: long (default), wide, and default-only
  - Support for cross-classification (one-to-many mappings)
  - Default category extraction for principal diagnosis analysis
  - Automatic type inference (diagnosis vs. procedure)

- **`get_ccsr_description()`**: Retrieve clinical descriptions for CCSR codes
  - Automatic download if mapping file not provided
  - Support for both diagnosis and procedure codes
  - Returns comprehensive description data frames

- **`list_ccsr_versions()`**: List available CCSR versions
  - Dynamic version discovery from HCUP website
  - Support for filtering by type (diagnosis/procedure)
  - Caching for improved performance

- **`ccsr_changelog()`**: Access CCSR change logs
  - Multiple formats: URL, text, view (PDF), download, and read (data table)
  - Interactive selection of change log files
  - Support for version ranges and specific versions
  - Automatic discovery of available change logs

#### HCUP Summary Trend Tables Functions
- **`download_trend_tables()`**: Download HCUP Summary Trend Tables
  - Interactive menu for table selection
  - Support for downloading all tables as ZIP file
  - Automatic fallback to individual downloads if ZIP unavailable
  - Dynamic discovery of available tables from HCUP website

- **`read_trend_table()`**: Read Summary Trend Table Excel files
  - Automatic cache discovery and interactive file selection
  - Interactive sheet selection (National, states, etc.)
  - Automatic metadata sheet detection and filtering
  - Support for data.table output

- **`list_trend_table_sheets()`**: List available sheets in trend table files
  - Identifies data sheets vs. metadata sheets
  - Provides sheet recommendations

#### Utility Functions
- **`hcup_citation()`**: Generate proper citations for HCUP resources
  - Support for CCSR and Summary Trend Tables
  - Multiple formats: text, BibTeX, and R citation objects
  - Automatic version detection for latest citations
  - Compliant with HCUP publishing requirements

### Technical Details
- UTF-8 encoding support for proper handling of special characters
- ICD-10 codes preserved as character strings with leading zeros
- Intelligent file caching to reduce network requests
- Comprehensive error messages and validation
- User-friendly interactive selection for files and options
- Support for tibbles and optional data.table output
- Automatic latest version detection and historical version support

### Documentation
- Comprehensive README with usage examples
- Detailed function documentation with roxygen2
- Vignette with complete workflow examples
- Legal disclaimer and compliance information
- Proper citation examples

### Compliance
- Only accesses publicly available, free HCUP resources
- Does NOT access paid HCUP databases (NIS, KID, SID, NEDS, etc.)
- Facilitates direct download from official HCUP website
- Includes proper legal disclaimers and user responsibility statements
- Provides links to all relevant HCUP policies and agreements
- Package is not affiliated with AHRQ/HCUP
