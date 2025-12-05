#' Generate Citation for HCUP Resources
#'
#' Provides recommended citations for HCUP resources including Clinical
#' Classifications Software Refined (CCSR) data and Summary Trend Tables from
#' the Agency for Healthcare Research and Quality (AHRQ) Healthcare Cost and
#' Utilization Project (HCUP).
#'
#' @param format Character string specifying the citation format. Must be one
#'   of: "text" (default), "bibtex", or "r" (for R citation object).
#' @param version Character string specifying the CCSR version to cite. If
#'   "latest" (default), the function will attempt to fetch the latest version
#'   from the HCUP website. Otherwise, specify a version like "v2026.1".
#' @param resource Character string specifying which HCUP resource to cite.
#'   Options: "ccsr" (default) for CCSR data, or "trend_tables" for Summary
#'   Trend Tables.
#'
#' @return If `format` is "text", returns a character string with the citation.
#'   If `format` is "bibtex", returns a character string with BibTeX format.
#'   If `format` is "r", returns an R citation object.
#'
#' @details
#' This function generates citations for HCUP resources following AHRQ/HCUP
#' guidelines. The citation includes the appropriate version number and
#' access date. For CCSR data, the version is automatically detected if not
#' specified. For Summary Trend Tables, the citation references the general
#' HCUP Summary Trend Tables resource.
#'
#' @examples
#' # Text citation for CCSR
#' hcup_citation()
#'
#' # BibTeX format for CCSR
#' hcup_citation(format = "bibtex")
#'
#' # Citation for Summary Trend Tables
#' hcup_citation(resource = "trend_tables")
#'
#' # R citation object
#' hcup_citation(format = "r")
#'
#' @importFrom utils person
#' @export
hcup_citation <- function(format = "text", version = "latest", resource = "ccsr") {
  # Validate format
  if (!format %in% c("text", "bibtex", "r")) {
    stop("`format` must be one of: 'text', 'bibtex', or 'r'")
  }
  
  # Validate resource
  resource <- tolower(resource)
  if (!resource %in% c("ccsr", "trend_tables", "trend")) {
    stop("`resource` must be one of: 'ccsr' or 'trend_tables'")
  }
  
  # Get current date for access date
  access_date <- format(Sys.Date(), "%B %d, %Y")
  
  # Handle Summary Trend Tables citation
  if (resource %in% c("trend_tables", "trend")) {
    if (format == "text") {
      citation_text <- paste0(
        "Agency for Healthcare Research and Quality. HCUP Summary Trend Tables. ",
        "Healthcare Cost and Utilization Project (HCUP). ",
        "Agency for Healthcare Research and Quality, Rockville, MD. ",
        "www.hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp. ",
        "Accessed ", access_date, ". "
      )
      return(citation_text)
    } else if (format == "bibtex") {
      citation_bibtex <- paste0(
        "@misc{hcup_trend_tables,\n",
        "  title = {HCUP Summary Trend Tables},\n",
        "  author = {{Agency for Healthcare Research and Quality}},\n",
        "  organization = {Healthcare Cost and Utilization Project (HCUP)},\n",
        "  publisher = {Agency for Healthcare Research and Quality},\n",
        "  address = {Rockville, MD},\n",
        "  year = {", format(Sys.Date(), "%Y"), "},\n",
        "  url = {https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp},\n",
        "  note = {Accessed ", access_date, "}\n",
        "}"
      )
      return(citation_bibtex)
    } else if (format == "r") {
      # Return R citation object for Trend Tables
      citation_r <- utils::bibentry(
        "Misc",
        title = "HCUP Summary Trend Tables",
        author = utils::person("Agency for Healthcare Research and Quality", role = "aut"),
        year = format(Sys.Date(), "%Y"),
        note = paste0("Accessed ", access_date),
        url = "https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp"
      )
      return(citation_r)
    }
  }
  
  # Handle CCSR citation (original functionality)
  # Get version if needed
  if (version == "latest") {
    tryCatch({
      version <- get_latest_version("diagnosis")
    }, error = function(e) {
      version <- "v2026.1"  # Fallback version
    })
  }
  
  # Validate version format
  if (!grepl("^v\\d{4}[-.]\\d+$", version)) {
    stop("`version` must be in format 'vYYYY.N' or 'vYYYY-N' (e.g., 'v2026.1')")
  }
  
  # Normalize version for display (use dot format)
  version_display <- gsub("-", ".", version)
  
  if (format == "text") {
    citation_text <- paste0(
      "Agency for Healthcare Research and Quality. Clinical Classifications Software Refined (CCSR) for ICD-10-CM Diagnoses, ",
      version_display, ". Healthcare Cost and Utilization Project (HCUP). ",
      "Agency for Healthcare Research and Quality, Rockville, MD. ",
      "www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp. Accessed ", access_date, ". "
    )
    return(citation_text)
  } else if (format == "bibtex") {
    citation_bibtex <- paste0(
      "@misc{hcup_ccsr_", gsub("[^0-9]", "", version_display), ",\n",
      "  title = {Clinical Classifications Software Refined (CCSR) for ICD-10-CM Diagnoses, ", version_display, "},\n",
      "  author = {{Agency for Healthcare Research and Quality}},\n",
      "  organization = {Healthcare Cost and Utilization Project (HCUP)},\n",
      "  publisher = {Agency for Healthcare Research and Quality},\n",
      "  address = {Rockville, MD},\n",
      "  year = {", sub("v(\\d{4})\\.(\\d+)", "\\1", version_display), "},\n",
      "  url = {https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp},\n",
      "  note = {Accessed ", access_date, "}\n",
      "}"
    )
    return(citation_bibtex)
  } else if (format == "r") {
    # Return R citation object for CCSR
    citation_r <- utils::bibentry(
      "Misc",
      title = paste0("Clinical Classifications Software Refined (CCSR) for ICD-10-CM Diagnoses, ", version_display),
      author = utils::person("Agency for Healthcare Research and Quality", role = "aut"),
      year = sub("v(\\d{4})\\.(\\d+)", "\\1", version_display),
      note = paste0("Accessed ", access_date),
      url = "https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp"
    )
    return(citation_r)
  }
}
