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
if (FALSE) { # \dontrun{
# Get latest change log URL
changelog_url <- ccsr_changelog(format = "url")

# Get change log information
changelog_info <- ccsr_changelog(version = "v2026.1", format = "text")

# Download change log file
changelog_file <- ccsr_changelog(version = "v2025.1", format = "download")

# View change log in default PDF viewer
ccsr_changelog(version = "v2026.1", format = "view")

# Extract text from change log PDF (requires pdftools package)
changelog_text <- ccsr_changelog(version = "v2026.1", format = "extract")
cat(changelog_text)
} # }
```
