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
#' @importFrom tidyr pivot_wider pivot_longer
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
  
  if (type == "diagnosis" && length(map_cols$ccsr_cols) == 0 && !default_only) {
    stop("Could not identify CCSR category columns in mapping data")
  }

  if (type == "procedure" && is.null(map_cols$ccsr_col)) {
    stop("Could not identify CCSR category column in mapping data")
  }
  
  # Prepare data for joining
  data_prep <- tibble::as_tibble(data)
  data_prep[[code_col]] <- format_icd_codes(data_prep[[code_col]])
  data_prep$.hcuptools_row_id <- seq_len(nrow(data_prep))
  
  mapping <- tibble::as_tibble(map_df)
  mapping <- normalize_ccsr_character_columns(mapping)
  mapping[[map_cols$icd_col]] <- format_icd_codes(mapping[[map_cols$icd_col]])
  
  if (type == "diagnosis") {
    mapping <- prepare_diagnosis_mapping(mapping, map_cols, default_only)
    join_cols <- c("icd_code", "ccsr_category", "ccsr_num", "is_default")
    join_by <- stats::setNames("icd_code", code_col)
  } else {
    join_cols <- c(map_cols$icd_col, map_cols$ccsr_col)
    if (!is.null(map_cols$desc_col)) {
      join_cols <- c(join_cols, map_cols$desc_col)
    }
    join_by <- stats::setNames(map_cols$icd_col, code_col)
    mapping <- mapping[, join_cols, drop = FALSE]
  }
  
  # Perform the join
  result <- dplyr::left_join(
    data_prep,
    mapping,
    by = join_by
  )
  
  # Handle output format
  if (output_format == "wide" && type == "diagnosis") {
    result <- reshape_to_wide(result, code_col)
  } else if (type == "diagnosis") {
    result$ccsr_num <- NULL
  }
  
  # Select columns if keep_all is FALSE
  if (!keep_all) {
    if (type == "diagnosis") {
      ccsr_keep_cols <- grep("^CCSR_\\d+$|^ccsr_category$|^is_default$", names(result), value = TRUE)
      keep_cols <- c(code_col, ccsr_keep_cols)
    } else {
      keep_cols <- c(code_col, map_cols$ccsr_col)
      if (!is.null(map_cols$desc_col)) {
        keep_cols <- c(keep_cols, map_cols$desc_col)
      }
    }
    result <- result[, names(result) %in% keep_cols, drop = FALSE]
  }

  result$.hcuptools_row_id <- NULL
  
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
  
  result <- list(icd_col = NULL, ccsr_col = NULL, ccsr_cols = character(0), default_col = NULL, desc_col = NULL)
  
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
  
  # Find CCSR category column(s)
  if (type == "procedure") {
    ccsr_patterns <- c("^prccsr$", "prccsr", "ccsr.*category", "ccsr.*code", "^ccsr$", "category")
    for (pattern in ccsr_patterns) {
      match <- grep(pattern, col_names, value = TRUE)
      if (length(match) > 0) {
        result$ccsr_col <- match[1]
        break
      }
    }
  } else {
    diagnosis_slot_cols <- grep("^ccsr.*category.*[1-6]$", col_names, value = TRUE)
    if (length(diagnosis_slot_cols) > 0) {
      slot_nums <- suppressWarnings(as.integer(gsub(".*?([1-6])$", "\\1", diagnosis_slot_cols)))
      diagnosis_slot_cols <- diagnosis_slot_cols[order(slot_nums)]
      result$ccsr_cols <- diagnosis_slot_cols
      result$ccsr_col <- diagnosis_slot_cols[1]
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
reshape_to_wide <- function(data, code_col) {
  id_cols <- setdiff(names(data), c("ccsr_category", "ccsr_num", "is_default"))
  base_rows <- unique(data[, id_cols, drop = FALSE])
  matched_rows <- data[!is.na(data$ccsr_num), , drop = FALSE]

  if (nrow(matched_rows) == 0) {
    return(base_rows)
  }

  wide_map <- matched_rows |>
    tidyr::pivot_wider(
      id_cols = dplyr::all_of(id_cols),
      names_from = ccsr_num,
      values_from = dplyr::all_of("ccsr_category"),
      names_prefix = "CCSR_"
    )
  result <- dplyr::left_join(base_rows, wide_map, by = id_cols)
  
  return(result)
}

#' Prepare diagnosis mapping for ICD-to-CCSR joins
#'
#' @noRd
prepare_diagnosis_mapping <- function(mapping, map_cols, default_only) {
  if (length(map_cols$ccsr_cols) == 0 && is.null(map_cols$default_col)) {
    stop("Could not identify diagnosis CCSR columns in mapping data")
  }

  if (length(map_cols$ccsr_cols) > 0) {
    long_map <- mapping |>
      tidyr::pivot_longer(
        cols = dplyr::all_of(map_cols$ccsr_cols),
        names_to = "ccsr_source_col",
        values_to = "ccsr_category"
      )
    long_map$ccsr_num <- suppressWarnings(as.integer(gsub(".*?([1-6])$", "\\1", long_map$ccsr_source_col)))
  } else {
    long_map <- mapping
    long_map$ccsr_category <- NA_character_
    long_map$ccsr_num <- NA_integer_
  }

  long_map$ccsr_category <- strip_surrounding_quotes(long_map$ccsr_category)
  long_map$icd_code <- format_icd_codes(long_map[[map_cols$icd_col]])

  if (!is.null(map_cols$default_col)) {
    default_vals <- strip_surrounding_quotes(long_map[[map_cols$default_col]])
    long_map$is_default <- !is.na(long_map$ccsr_category) &
      nzchar(long_map$ccsr_category) &
      long_map$ccsr_category == default_vals
  } else {
    long_map$is_default <- NA
  }

  long_map <- long_map[!is.na(long_map$ccsr_category) & nzchar(long_map$ccsr_category), , drop = FALSE]

  if (default_only) {
    if (!is.null(map_cols$default_col)) {
      long_map <- long_map[!is.na(long_map$is_default) & long_map$is_default, , drop = FALSE]
    } else {
      long_map <- long_map[0, , drop = FALSE]
    }
  }

  unique(long_map[, c("icd_code", "ccsr_category", "ccsr_num", "is_default"), drop = FALSE])
}

# Declare global variables to avoid R CMD check notes
utils::globalVariables("ccsr_num")

