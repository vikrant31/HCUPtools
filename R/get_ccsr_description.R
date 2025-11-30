#' Get CCSR Category Descriptions
#'
#' Retrieves the full clinical description for one or more CCSR category codes.
#' This function helps users interpret CCSR codes by providing their meaningful
#' clinical descriptions.
#'
#' @param ccsr_codes Character vector of CCSR category codes (e.g., "ADM010",
#'   "NEP003", "CIR019").
#' @param map_df Optional. A tibble containing CCSR mapping data with
#'   descriptions. If provided, descriptions are extracted from this data frame.
#'   If NULL (default), the function will attempt to download the latest mapping
#'   file to extract descriptions.
#' @param type Character string specifying the type of CCSR codes. Must be one
#'   of: "diagnosis" (or "dx") or "procedure" (or "pr"). If NULL (default), the
#'   function will attempt to infer the type from the codes or mapping data.
#'
#' @return A tibble with columns:
#'   - `ccsr_code`: The CCSR category code
#'   - `description`: The full clinical description
#'   - Additional metadata columns if available in the mapping data
#'
#' @details
#' CCSR category codes follow specific naming conventions:
#' - Diagnosis codes: Typically start with letters (e.g., "ADM010", "NEP003")
#' - Procedure codes: Typically start with letters (e.g., "PRC001", "PRC002")
#'
#' If a description is not found for a code, it will be marked as NA in the
#' result.
#'
#' @examples
#' \dontrun{
#' # Get descriptions using downloaded mapping data
#' dx_map <- download_ccsr("diagnosis")
#' get_ccsr_description(c("ADM010", "NEP003", "CIR019"), map_df = dx_map)
#'
#' # Get descriptions without pre-downloaded data (will download automatically)
#' get_ccsr_description(c("ADM010", "NEP003"), type = "diagnosis")
#' }
#'
#' @importFrom dplyr distinct filter left_join
#' @importFrom tibble tibble
#' @importFrom stats setNames
#' @importFrom rlang .data
#' @export
get_ccsr_description <- function(ccsr_codes,
                                 map_df = NULL,
                                 type = NULL) {
  
  # Validate inputs
  if (!is.character(ccsr_codes) || length(ccsr_codes) == 0) {
    stop("`ccsr_codes` must be a non-empty character vector")
  }
  
  # If map_df is not provided, download it
  if (is.null(map_df)) {
    if (is.null(type)) {
      # Try to infer type from codes (simple heuristic)
      if (any(grepl("^PRC", ccsr_codes, ignore.case = TRUE))) {
        type <- "procedure"
      } else {
        type <- "diagnosis"  # Default
      }
    }
    
    message("Downloading CCSR mapping file to extract descriptions...")
    map_df <- download_ccsr(type = type, version = "latest")
  }
  
  # Infer type from map_df if not provided
  if (is.null(type)) {
    type <- infer_ccsr_type(map_df)
  }
  
  # Find description column
  col_names <- tolower(names(map_df))
  desc_col <- NULL
  
  desc_patterns <- c("ccsr.*description", "description", "label", "name", "desc")
  for (pattern in desc_patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      desc_col <- match[1]
      break
    }
  }
  
  if (is.null(desc_col)) {
    stop("Could not find description column in mapping data")
  }
  
  # Find CCSR code column
  ccsr_col <- NULL
  ccsr_patterns <- c("ccsr.*category", "ccsr.*code", "^ccsr$", "category")
  for (pattern in ccsr_patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      ccsr_col <- match[1]
      break
    }
  }
  
  if (is.null(ccsr_col)) {
    stop("Could not find CCSR code column in mapping data")
  }
  
  # Extract unique descriptions
  unique_map <- map_df[, c(ccsr_col, desc_col)] |>
    dplyr::distinct() |>
    dplyr::filter(!is.na(.data[[ccsr_col]]))
  
  # Match codes to descriptions
  join_by <- stats::setNames(ccsr_col, "ccsr_code")
  result <- tibble::tibble(ccsr_code = ccsr_codes) |>
    dplyr::left_join(
      unique_map,
      by = join_by
    )
  
  # Rename description column for clarity
  names(result)[names(result) == desc_col] <- "description"
  
  # Check for unmatched codes
  unmatched <- is.na(result$description)
  if (any(unmatched)) {
    warning("No description found for ", sum(unmatched), " code(s): ",
            paste(ccsr_codes[unmatched], collapse = ", "))
  }
  
  return(result)
}

