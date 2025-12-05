#' Map ICD-10 Codes to CCSR Categories
#'
#' Maps ICD-10-CM diagnosis codes or ICD-10-PCS procedure codes to their
#' corresponding CCSR categories using a downloaded CCSR mapping file.
#'
#' @param data A data frame or tibble containing ICD-10 codes to be mapped.
#' @param code_col Character string specifying the name of the column in `data`
#'   that contains the ICD-10 codes.
#' @param map_df A tibble containing the CCSR mapping data, typically obtained
#'   from `download_ccsr()`.
#' @param type Character string specifying the type of mapping. Must be one of:
#'   "diagnosis" (or "dx") for ICD-10-CM codes, or "procedure" (or "pr") for
#'   ICD-10-PCS codes. If NULL (default), the function will attempt to infer
#'   the type from the mapping data frame.
#' @param default_only Logical. For diagnosis codes only, if TRUE, returns only
#'   the default CCSR category (recommended for principal diagnosis analysis).
#'   If FALSE (default), returns all assigned CCSR categories including
#'   cross-classifications.
#' @param output_format Character string specifying the output format. Must be
#'   one of: "long" (default) or "wide". "long" format duplicates records for
#'   each assigned CCSR category. "wide" format creates multiple columns
#'   (CCSR_1, CCSR_2, etc.) for multiple categories.
#' @param keep_all Logical. If TRUE (default), returns all original columns
#'   from `data` plus the CCSR mapping columns. If FALSE, returns only the
#'   ICD-10 code column and CCSR mapping columns.
#'
#' @return A tibble with the original data plus CCSR mapping columns. The
#'   structure depends on `output_format`:
#'   - For "long" format: Each row represents one ICD-10 code and one CCSR
#'     category assignment (rows are duplicated for multiple categories).
#'   - For "wide" format: Each row represents one ICD-10 code with multiple
#'     CCSR category columns (CCSR_1, CCSR_2, etc.).
#'
#' @details
#' CCSR allows for cross-classification, meaning a single ICD-10 code can map
#' to multiple CCSR categories. The "long" format is recommended for analyses
#' where you want to count all assigned CCSR categories, while "wide" format
#' may be more convenient for patient-level analyses.
#'
#' For diagnosis codes, CCSR also assigns a "default" category that is
#' recommended for principal diagnosis analysis. Use `default_only = TRUE` to
#' extract only this default category.
#'
#' @examples
#' \donttest{
#' # Download mapping file
#' dx_map <- download_ccsr("diagnosis")
#'
#' # Create sample data
#' sample_data <- tibble::tibble(
#'   patient_id = 1:3,
#'   icd10_code = c("E11.9", "I10", "M79.3")
#' )
#'
#' # Map codes (long format - default)
#' mapped_long <- ccsr_map(
#'   data = sample_data,
#'   code_col = "icd10_code",
#'   map_df = dx_map
#' )
#'
#' # Map codes (wide format)
#' mapped_wide <- ccsr_map(
#'   data = sample_data,
#'   code_col = "icd10_code",
#'   map_df = dx_map,
#'   output_format = "wide"
#' )
#'
#' # Map codes (default category only)
#' mapped_default <- ccsr_map(
#'   data = sample_data,
#'   code_col = "icd10_code",
#'   map_df = dx_map,
#'   default_only = TRUE
#' )
#' }
#'
#' @importFrom dplyr left_join mutate group_by ungroup across all_of row_number desc
#' @importFrom tidyr pivot_wider
#' @importFrom tibble as_tibble
#' @importFrom stats setNames
#' @importFrom rlang .data
#' @export
ccsr_map <- function(data,
                    code_col,
                    map_df,
                    type = NULL,
                    default_only = FALSE,
                    output_format = "long",
                    keep_all = TRUE) {
  
  # Validate inputs
  if (!inherits(data, "data.frame")) {
    stop("`data` must be a data frame or tibble")
  }
  
  if (!code_col %in% names(data)) {
    stop("Column '", code_col, "' not found in `data`")
  }
  
  if (!inherits(map_df, "data.frame")) {
    stop("`map_df` must be a data frame or tibble")
  }
  
  if (!output_format %in% c("long", "wide")) {
    stop("`output_format` must be one of: 'long' or 'wide'")
  }
  
  # Infer type from mapping data if not provided
  if (is.null(type)) {
    type <- infer_ccsr_type(map_df)
  } else {
    type <- tolower(type)
    if (type %in% c("dx", "diagnosis")) {
      type <- "diagnosis"
    } else if (type %in% c("pr", "procedure")) {
      type <- "procedure"
    } else {
      stop("`type` must be one of: 'diagnosis'/'dx' or 'procedure'/'pr'")
    }
  }
  
  # Find relevant columns in mapping data
  map_cols <- identify_mapping_columns(map_df, type, default_only)
  
  if (is.null(map_cols$icd_col)) {
    stop("Could not identify ICD-10 code column in mapping data")
  }
  
  if (is.null(map_cols$ccsr_col)) {
    stop("Could not identify CCSR category column in mapping data")
  }
  
  # Prepare data for joining
  data_prep <- tibble::as_tibble(data)
  data_prep[[code_col]] <- format_icd_codes(data_prep[[code_col]])
  
  mapping <- tibble::as_tibble(map_df)
  mapping[[map_cols$icd_col]] <- format_icd_codes(mapping[[map_cols$icd_col]])
  
  # Filter mapping data if default_only is TRUE (diagnosis only)
  if (default_only && type == "diagnosis" && !is.null(map_cols$default_col)) {
    mapping <- mapping[!is.na(mapping[[map_cols$default_col]]), ]
    # Use default column as the CCSR column
    map_cols$ccsr_col <- map_cols$default_col
  }
  
  # Prepare join columns
  join_cols <- c(map_cols$icd_col, map_cols$ccsr_col)
  if (!is.null(map_cols$desc_col)) {
    join_cols <- c(join_cols, map_cols$desc_col)
  }
  
  # Perform the join
  join_by <- stats::setNames(map_cols$icd_col, code_col)
  result <- dplyr::left_join(
    data_prep,
    mapping[, join_cols],
    by = join_by
  )
  
  # Handle output format
  if (output_format == "wide" && type == "diagnosis" && !default_only) {
    # For wide format with multiple categories, we need to reshape
    result <- reshape_to_wide(result, code_col, map_cols$ccsr_col)
  }
  
  # Select columns if keep_all is FALSE
  if (!keep_all) {
    keep_cols <- c(code_col, map_cols$ccsr_col)
    if (!is.null(map_cols$desc_col)) {
      keep_cols <- c(keep_cols, map_cols$desc_col)
    }
    result <- result[, names(result) %in% c(keep_cols, names(data)), ]
  }
  
  return(result)
}

#' Infer CCSR type from mapping data frame
#'
#' @noRd
infer_ccsr_type <- function(map_df) {
  col_names <- tolower(names(map_df))
  
  # Check for diagnosis indicators
  dx_indicators <- c("dxccsr", "diagnosis", "icd.*10.*cm", "dx.*ccsr")
  if (any(sapply(dx_indicators, function(p) any(grepl(p, col_names))))) {
    return("diagnosis")
  }
  
  # Check for procedure indicators
  pr_indicators <- c("prccsr", "procedure", "icd.*10.*pcs", "pr.*ccsr")
  if (any(sapply(pr_indicators, function(p) any(grepl(p, col_names))))) {
    return("procedure")
  }
  
  # Check column values - look for common diagnosis vs procedure patterns
  # Diagnosis codes typically have dots (E11.9), procedures don't
  code_col <- grep("icd|code|dx|pr", col_names, value = TRUE)[1]
  if (!is.na(code_col) && code_col %in% names(map_df)) {
    sample_codes <- utils::head(map_df[[code_col]][!is.na(map_df[[code_col]])], 100)
    if (length(sample_codes) > 0) {
      # Check if codes contain dots (diagnosis) or are alphanumeric without dots (procedure)
      has_dots <- any(grepl("\\.", sample_codes))
      if (has_dots) {
        return("diagnosis")
      } else if (any(grepl("^[0-9]", sample_codes))) {
        # Procedure codes often start with numbers
        return("procedure")
      }
    }
  }
  
  # Default to diagnosis if unclear (but suppress warning if we have some evidence)
  # Only warn if we really can't tell
  if (is.null(code_col)) {
    warning("Could not infer CCSR type from mapping data, defaulting to 'diagnosis'")
  }
  return("diagnosis")
}

#' Identify relevant columns in mapping data frame
#'
#' @noRd
identify_mapping_columns <- function(map_df, type, default_only) {
  col_names <- tolower(names(map_df))
  
  result <- list(icd_col = NULL, ccsr_col = NULL, default_col = NULL, desc_col = NULL)
  
  # Find ICD code column
  if (type == "diagnosis") {
    icd_patterns <- c("icd.*10.*cm", "icd.*10", "diagnosis.*code", "^code$", "^dx$")
  } else {
    icd_patterns <- c("icd.*10.*pcs", "icd.*10", "procedure.*code", "^code$", "^pr$")
  }
  
  for (pattern in icd_patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      result$icd_col <- match[1]
      break
    }
  }
  
  # Find CCSR category column
  # For procedures, look for "prccsr" first, then general patterns
  if (type == "procedure") {
    ccsr_patterns <- c("^prccsr$", "prccsr", "ccsr.*category", "ccsr.*code", "^ccsr$", "category")
  } else {
    ccsr_patterns <- c("ccsr.*category", "ccsr.*code", "^ccsr$", "category")
  }
  for (pattern in ccsr_patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      result$ccsr_col <- match[1]
      break
    }
  }
  
  # Find default CCSR column (diagnosis only)
  if (type == "diagnosis") {
    default_patterns <- c("default.*ccsr", "default.*category", "default")
    for (pattern in default_patterns) {
      match <- grep(pattern, col_names, value = TRUE)
      if (length(match) > 0) {
        result$default_col <- match[1]
        break
      }
    }
  }
  
  # Find description column
  desc_patterns <- c("description", "label", "name", "desc")
  for (pattern in desc_patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      result$desc_col <- match[1]
      break
    }
  }
  
  return(result)
}

#' Reshape result to wide format
#'
#' @noRd
reshape_to_wide <- function(data, code_col, ccsr_col) {
  # For wide format, we need to handle multiple CCSR categories per code
  # This is a simplified version - in practice, you might want more sophisticated handling
  
  # Group by all columns except CCSR, then create numbered CCSR columns
  group_cols <- setdiff(names(data), c(ccsr_col, code_col))
  
  if (length(group_cols) > 0) {
    data <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(c(code_col, group_cols)))) |>
      dplyr::mutate(ccsr_num = dplyr::row_number()) |>
      dplyr::ungroup()
  } else {
    data <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(code_col))) |>
      dplyr::mutate(ccsr_num = dplyr::row_number()) |>
      dplyr::ungroup()
  }
  
  # Pivot to wide format
  result <- data |>
    tidyr::pivot_wider(
      names_from = ccsr_num,
      values_from = dplyr::all_of(ccsr_col),
      names_prefix = "CCSR_"
    )
  
  return(result)
}

# Declare global variables to avoid R CMD check notes
utils::globalVariables("ccsr_num")

