#' Read CCSR Mapping Files from Disk
#'
#' Reads previously downloaded CCSR mapping files from disk. If no file path is
#' provided, automatically finds and reads cached files from `download_ccsr()`.
#'
#' @param file_path Optional character string, path to a CCSR mapping file. Can be:
#'   - A ZIP file path (will be extracted and read)
#'   - A CSV/Excel file path (will be read directly)
#'   - A directory path containing extracted CCSR files
#'   If NULL (default), automatically searches the cache directory for files
#'   downloaded via `download_ccsr()`.
#' @param type Character string specifying the type of CCSR file. Must be one
#'   of: "diagnosis" (or "dx") for ICD-10-CM diagnosis codes, or "procedure"
#'   (or "pr") for ICD-10-PCS procedure codes. If NULL and `file_path` is NULL,
#'   defaults to "diagnosis". If `file_path` is provided, the function will
#'   attempt to infer the type from the file name or contents.
#' @param version Character string specifying the CCSR version to read from cache.
#'   Use "latest" (default) to read the most recent version, or specify a version
#'   like "v2026.1", "v2025.1", etc. Only used when `file_path` is NULL.
#' @param clean_names Logical. If TRUE (default), column names are cleaned to
#'   follow R naming conventions (snake_case).
#' @param as_data_table Logical or NULL. If TRUE and the `data.table` package is
#'   available, returns a `data.table` object instead of a tibble. If FALSE,
#'   returns a tibble. If NULL (default), prompts the user interactively to
#'   choose (only in interactive sessions). In non-interactive sessions, defaults
#'   to FALSE. Note: tibbles are already data frames and work with all standard
#'   R data frame operations.
#' @param name Optional character string, suggested variable name for the
#'   returned data. This is only used for display/messaging purposes and does
#'   not automatically assign the data to a variable. You must still assign the
#'   result: `my_data <- read_ccsr()`. If NULL (default), a name is suggested
#'   based on the file type and version.
#'
#' @return A tibble (or data.table if `as_data_table = TRUE`) containing the
#'   CCSR mapping data. Tibbles are data frames and can be used with all
#'   standard R data frame operations, including `dplyr`, `data.table`, and
#'   base R functions.
#'
#' @note To use the data, assign it to a variable:
#'   `my_data <- read_ccsr()`. The `name` parameter is only for display
#'   purposes and does not automatically assign the data.
#'
#' @details
#' This function can read CCSR files in several formats:
#' - ZIP files downloaded from HCUP (will extract and read the CSV/Excel file)
#' - CSV files (extracted from ZIP or saved separately)
#' - Excel files (if `readxl` package is available)
#' - Directories containing extracted files
#' - Cached files from `download_ccsr()` (automatic if `file_path` is NULL)
#'
#' The function automatically detects the file format and handles encoding
#' issues, preserving leading zeros in ICD-10 codes.
#'
#' When `file_path` is NULL, the function automatically searches the cache
#' directory (`tempdir()/HCUPtools_cache/`) for files matching the specified
#' `type` and `version`. This makes it easy to read previously downloaded
#' files without needing to know the exact file path.
#'
#' @examples
#' \donttest{
#' # Automatically read latest cached diagnosis file
#' # Assign to a variable to use the data
#' dx_map <- read_ccsr()
#'
#' # Read specific version from cache with suggested name
#' dx_map_v2025 <- read_ccsr(type = "diagnosis", version = "v2025.1", name = "dx_map_v2025")
#'
#' # Read procedure file from cache
#' pr_map <- read_ccsr(type = "procedure")
#'
#' # Read from a specific file path (manual)
#' dx_map <- read_ccsr("path/to/DXCCSR-v2026-1.zip")
#'
#' # Read from a CSV file
#' dx_map <- read_ccsr("path/to/DXCCSR_v2026_1.csv")
#'
#' # Read from a directory
#' dx_map <- read_ccsr("path/to/extracted_ccsr_files/")
#'
#' # Use the data after assignment
#' head(dx_map)
#' nrow(dx_map)
#' }
#'
#' @importFrom readr read_csv cols locale
#' @importFrom tibble as_tibble
#' @importFrom utils unzip
#' @importFrom readxl read_excel
#' @export
read_ccsr <- function(file_path = NULL,
                     type = NULL,
                     version = "latest",
                     clean_names = TRUE,
                     as_data_table = NULL,
                     name = NULL) {
  
  # Determine suggested variable name early (estimate based on type/version)
  # We'll refine it later once we have the actual file_path
  suggested_name <- determine_suggested_name(name, type, version, file_path)
  
  # Handle interactive prompt for as_data_table FIRST (before file selection)
  # Show the tip along with the data.table question
  if (is.null(as_data_table)) {
    as_data_table <- prompt_for_data_table(suggested_name, "read_ccsr")
  }
  
  # If no file_path provided, automatically find cached file or show interactive menu
  if (is.null(file_path)) {
    cached_files <- list_cached_ccsr_files(type)
    
    if (length(cached_files) == 0) {
      stop("No cached CCSR file found. ",
           "Please download a file first using `download_ccsr()` ",
           "or provide a `file_path`.")
    }
    
    # If only one file, use it automatically
    if (length(cached_files) == 1) {
      file_path <- cached_files[[1]]$path
      message("Reading cached file: ", basename(file_path))
    } else {
      # Multiple files - show interactive menu
      file_path <- select_cached_ccsr_file_interactive(cached_files, type, version)
    }
  }
  
  # Validate file path
  if (!file.exists(file_path)) {
    stop("File or directory not found: ", file_path)
  }
  
  # Determine if it's a file or directory
  is_dir <- dir.exists(file_path)
  is_zip <- grepl("\\.zip$", file_path, ignore.case = TRUE)
  is_csv <- grepl("\\.csv$", file_path, ignore.case = TRUE)
  is_xlsx <- grepl("\\.xlsx?$", file_path, ignore.case = TRUE)
  
  # Update suggested variable name now that we have the actual file_path
  suggested_name <- determine_suggested_name(name, type, version, file_path)
  
  # Handle ZIP files
  if (is_zip) {
    result <- read_ccsr_from_zip(file_path, type, clean_names)
    result <- convert_to_data_table_if_requested(result, as_data_table)
    show_assignment_message(suggested_name, result)
    return(result)
  }
  
  # Handle directories
  if (is_dir) {
    result <- read_ccsr_from_dir(file_path, type, clean_names)
    result <- convert_to_data_table_if_requested(result, as_data_table)
    show_assignment_message(suggested_name, result)
    return(result)
  }
  
  # Handle CSV files
  if (is_csv) {
    result <- read_ccsr_from_csv(file_path, type, clean_names)
    result <- convert_to_data_table_if_requested(result, as_data_table)
    show_assignment_message(suggested_name, result)
    return(result)
  }
  
  # Handle Excel files
  if (is_xlsx) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required for reading Excel files. ",
           "Install it with: install.packages('readxl')")
    }
    result <- read_ccsr_from_excel(file_path, type, clean_names)
    result <- convert_to_data_table_if_requested(result, as_data_table)
    show_assignment_message(suggested_name, result)
    return(result)
  }
  
  stop("Unsupported file format. Expected ZIP, CSV, Excel, or directory.")
}

#' Read CCSR from ZIP file
#' @noRd
read_ccsr_from_zip <- function(zip_path, type, clean_names) {
  # Create temporary extraction directory
  extract_dir <- tempfile("ccsr_extract_")
  dir.create(extract_dir, showWarnings = FALSE)
  on.exit(unlink(extract_dir, recursive = TRUE), add = TRUE)
  
  # Extract ZIP file
  utils::unzip(zip_path, exdir = extract_dir)
  
  # Find CSV or Excel files in extracted directory
  files <- list.files(extract_dir, full.names = TRUE, recursive = TRUE)
  csv_files <- files[grepl("\\.csv$", files, ignore.case = TRUE)]
  xlsx_files <- files[grepl("\\.xlsx?$", files, ignore.case = TRUE)]
  
  # Prefer CSV, fall back to Excel
  if (length(csv_files) > 0) {
    # Use the first CSV file (or try to find the right one based on type)
    target_file <- select_ccsr_file(csv_files, type)
    return(read_ccsr_from_csv(target_file, type, clean_names))
  } else if (length(xlsx_files) > 0) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required for reading Excel files. ",
           "Install it with: install.packages('readxl')")
    }
    target_file <- select_ccsr_file(xlsx_files, type)
    return(read_ccsr_from_excel(target_file, type, clean_names))
  } else {
    stop("No CSV or Excel files found in ZIP archive")
  }
}

#' Read CCSR from directory
#' @noRd
read_ccsr_from_dir <- function(dir_path, type, clean_names) {
  # Find CSV or Excel files
  files <- list.files(dir_path, full.names = TRUE, recursive = TRUE)
  csv_files <- files[grepl("\\.csv$", files, ignore.case = TRUE)]
  xlsx_files <- files[grepl("\\.xlsx?$", files, ignore.case = TRUE)]
  
  if (length(csv_files) > 0) {
    target_file <- select_ccsr_file(csv_files, type)
    return(read_ccsr_from_csv(target_file, type, clean_names))
  } else if (length(xlsx_files) > 0) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required for reading Excel files. ",
           "Install it with: install.packages('readxl')")
    }
    target_file <- select_ccsr_file(xlsx_files, type)
    return(read_ccsr_from_excel(target_file, type, clean_names))
  } else {
    stop("No CSV or Excel files found in directory")
  }
}

#' Read CCSR from CSV file
#' @noRd
read_ccsr_from_csv <- function(csv_path, type, clean_names) {
  # Try different encodings
  encodings <- c("UTF-8", "latin1", "ISO-8859-1")
  data <- NULL
  
  for (enc in encodings) {
    tryCatch({
      data <- readr::read_csv(
        csv_path,
        locale = readr::locale(encoding = enc),
        col_types = readr::cols(.default = "c"),
        show_col_types = FALSE,
        progress = FALSE
      )
      break
    }, error = function(e) {
      # Try next encoding
    })
  }
  
  if (is.null(data)) {
    stop("Failed to read CSV file. Tried encodings: ", paste(encodings, collapse = ", "))
  }
  
  # Convert to tibble
  data <- tibble::as_tibble(data)
  
  # Clean column names if requested
  if (clean_names) {
    names(data) <- gsub("\\s+", "_", names(data))
    names(data) <- gsub("[^A-Za-z0-9_]", "", names(data))
    names(data) <- tolower(names(data))
    names(data) <- gsub("_+", "_", names(data))
    names(data) <- gsub("^_|_$", "", names(data))
  }
  
  # Preserve leading zeros in ICD codes
  # Infer type if not provided
  if (is.null(type)) {
    col_names <- tolower(names(data))
    if (any(grepl("dxccsr|diagnosis|icd.*10.*cm", col_names))) {
      type <- "diagnosis"
    } else if (any(grepl("prccsr|procedure|icd.*10.*pcs", col_names))) {
      type <- "procedure"
    } else {
      type <- "diagnosis"  # Default
    }
  }
  
  # Find ICD column
  col_names <- tolower(names(data))
  if (type == "diagnosis") {
    patterns <- c("icd.*10.*cm", "icd.*10", "diagnosis.*code", "^code$", "^dx$")
  } else {
    patterns <- c("icd.*10.*pcs", "icd.*10", "procedure.*code", "^code$", "^pr$")
  }
  
  icd_col <- NULL
  for (pattern in patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      icd_col <- match[1]
      break
    }
  }
  
  if (!is.null(icd_col) && icd_col %in% names(data)) {
    # Format ICD codes (preserve leading zeros)
    data[[icd_col]] <- trimws(as.character(data[[icd_col]]))
  }
  
  return(data)
}

#' Read CCSR from Excel file
#' @noRd
read_ccsr_from_excel <- function(excel_path, type, clean_names) {
  # Read first sheet
  data <- readxl::read_excel(excel_path, sheet = 1)
  
  # Convert to tibble
  data <- tibble::as_tibble(data)
  
  # Clean column names if requested
  if (clean_names) {
    names(data) <- gsub("\\s+", "_", names(data))
    names(data) <- gsub("[^A-Za-z0-9_]", "", names(data))
    names(data) <- tolower(names(data))
    names(data) <- gsub("_+", "_", names(data))
    names(data) <- gsub("^_|_$", "", names(data))
  }
  
  # Preserve leading zeros in ICD codes
  # Infer type if not provided
  if (is.null(type)) {
    col_names <- tolower(names(data))
    if (any(grepl("dxccsr|diagnosis|icd.*10.*cm", col_names))) {
      type <- "diagnosis"
    } else if (any(grepl("prccsr|procedure|icd.*10.*pcs", col_names))) {
      type <- "procedure"
    } else {
      type <- "diagnosis"  # Default
    }
  }
  
  # Find ICD column
  col_names <- tolower(names(data))
  if (type == "diagnosis") {
    patterns <- c("icd.*10.*cm", "icd.*10", "diagnosis.*code", "^code$", "^dx$")
  } else {
    patterns <- c("icd.*10.*pcs", "icd.*10", "procedure.*code", "^code$", "^pr$")
  }
  
  icd_col <- NULL
  for (pattern in patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      icd_col <- match[1]
      break
    }
  }
  
  if (!is.null(icd_col) && icd_col %in% names(data)) {
    # Format ICD codes (preserve leading zeros)
    data[[icd_col]] <- trimws(as.character(data[[icd_col]]))
  }
  
  return(data)
}

#' Select appropriate CCSR file from multiple files
#' @noRd
select_ccsr_file <- function(files, type) {
  if (length(files) == 1) {
    return(files[1])
  }
  
  # If type is specified, try to match
  if (!is.null(type)) {
    type <- tolower(type)
    if (type %in% c("dx", "diagnosis")) {
      pattern <- "dx|diagnosis"
    } else if (type %in% c("pr", "procedure")) {
      pattern <- "pr|procedure"
    } else {
      pattern <- NULL
    }
    
    if (!is.null(pattern)) {
      matches <- grep(pattern, files, ignore.case = TRUE, value = TRUE)
      if (length(matches) > 0) {
        return(matches[1])
      }
    }
  }
  
  # Default to first file
  return(files[1])
}


#' List all cached CCSR files
#' @noRd
list_cached_ccsr_files <- function(type = NULL) {
  cache_dir <- file.path(tempdir(), "HCUPtools_cache")
  if (!dir.exists(cache_dir)) {
    return(list())
  }
  
  all_files <- list.files(cache_dir, full.names = TRUE, pattern = "\\.zip$", ignore.case = TRUE)
  
  if (length(all_files) == 0) {
    return(list())
  }
  
  # Parse file information
  files_info <- list()
  for (file in all_files) {
    basename_file <- basename(file)
    
    # Determine type
    file_type <- if (grepl("DXCCSR", basename_file, ignore.case = TRUE)) {
      "diagnosis"
    } else if (grepl("PRCCSR", basename_file, ignore.case = TRUE)) {
      "procedure"
    } else {
      "unknown"
    }
    
    # Extract version
    version_match <- regmatches(basename_file, 
                               regexpr("v\\d{4}[-.]\\d+", basename_file, 
                                      ignore.case = TRUE))
    version <- if (length(version_match) > 0) version_match[1] else "unknown"
    
    # Filter by type if specified
    if (!is.null(type)) {
      type <- tolower(type)
      if (type %in% c("dx", "diagnosis") && file_type != "diagnosis") {
        next
      } else if (type %in% c("pr", "procedure") && file_type != "procedure") {
        next
      }
    }
    
    files_info[[length(files_info) + 1]] <- list(
      path = file,
      type = file_type,
      version = version,
      basename = basename_file
    )
  }
  
  return(files_info)
}

#' @noRd
select_cached_ccsr_file_interactive <- function(cached_files, type = NULL, version = "latest") {
  # Filter by version if specified
  if (version != "latest") {
    version_url <- gsub("\\.", "-", version)
    version_pattern <- paste0("v", gsub("v", "", version_url))
    version_pattern_alt <- gsub("-", "_", version_pattern)
    
    matching_version <- sapply(cached_files, function(f) {
      grepl(paste0(version_pattern, "|", version_pattern_alt), f$version, ignore.case = TRUE)
    })
    
    if (any(matching_version)) {
      cached_files <- cached_files[matching_version]
    }
  }
  
  # If only one after filtering, return it
  if (length(cached_files) == 1) {
    return(cached_files[[1]]$path)
  }
  
  # Show interactive menu
  cat("\n=== Available Cached CCSR Files ===\n\n")
  for (i in seq_along(cached_files)) {
    f <- cached_files[[i]]
    cat(sprintf("%2d. %s (%s, %s)\n", 
                i, 
                f$basename, 
                tools::toTitleCase(f$type),
                f$version))
  }
  cat("\n")
  
  # Get user selection
  if (interactive()) {
    selection <- readline("Select a file (enter number): ")
    selection <- as.integer(selection)
    
    if (is.na(selection) || selection < 1 || selection > length(cached_files)) {
      stop("Invalid selection. Please run the function again and select a valid number.")
    }
    
    return(cached_files[[selection]]$path)
  } else {
    # Non-interactive: return latest or first
    if (version == "latest") {
      # Sort by version and return latest
      versions <- sapply(cached_files, function(f) f$version)
      version_nums <- gsub("v", "", versions)
      version_nums <- gsub("-", ".", version_nums)
      version_parts <- strsplit(version_nums, "\\.")
      years <- as.numeric(sapply(version_parts, function(x) x[1]))
      minors <- as.numeric(sapply(version_parts, function(x) x[2]))
      sorted_idx <- order(years, minors, decreasing = TRUE)
      return(cached_files[[sorted_idx[1]]]$path)
    } else {
      return(cached_files[[1]]$path)
    }
  }
}

#' Prompt user for data.table preference (interactive only)
#' @noRd
prompt_for_data_table <- function(suggested_name = NULL, func_name = "read_ccsr") {
  # Check if data.table is available
  has_data_table <- requireNamespace("data.table", quietly = TRUE)
  
  if (!interactive()) {
    # Non-interactive: default to FALSE (tibble)
    return(FALSE)
  }
  
  if (!has_data_table) {
    # data.table not available: return FALSE
    return(FALSE)
  }
  
  # Interactive session with data.table available: ask user
  cat("\n")
  
  # Show tip about assigning to variable along with the data.table question
  if (!is.null(suggested_name)) {
    cat("Tip: Assign the result to a variable to use the data:\n")
    cat("  ", suggested_name, " <- ", func_name, "(...)\n", sep = "")
    cat("\n")
  }
  
  cat("Would you like to import as a data.table? (faster for large datasets)\n")
  cat("  [1] Yes (data.table)\n")
  cat("  [2] No (tibble/data.frame) - default\n")
  cat("Enter choice (1 or 2, or press Enter for default): ")
  
  choice <- readline()
  choice <- trimws(choice)
  
  if (choice == "1" || tolower(choice) == "y" || tolower(choice) == "yes") {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

#' @noRd
convert_to_data_table_if_requested <- function(data, as_data_table) {
  if (as_data_table) {
    if (requireNamespace("data.table", quietly = TRUE)) {
      return(data.table::as.data.table(data))
    } else {
      warning("Package 'data.table' is not available. Returning tibble instead. ",
              "Install it with: install.packages('data.table')")
      return(data)
    }
  }
  return(data)
}


#' Determine suggested variable name for the data
#' @noRd
determine_suggested_name <- function(name, type, version, file_path) {
  if (!is.null(name) && is.character(name) && length(name) == 1 && nchar(name) > 0) {
    # User provided a name, use it
    return(name)
  }
  
  # Generate suggested name based on type and version
  type_abbrev <- if (is.null(type)) {
    "ccsr"
  } else if (tolower(type) %in% c("dx", "diagnosis")) {
    "dx_map"
  } else if (tolower(type) %in% c("pr", "procedure")) {
    "pr_map"
  } else {
    "ccsr_map"
  }
  
  # Add version if available
  if (!is.null(version) && version != "latest") {
    version_clean <- gsub("[^0-9]", "", version)
    if (nchar(version_clean) > 0) {
      type_abbrev <- paste0(type_abbrev, "_v", version_clean)
    }
  }
  
  return(type_abbrev)
}

#' Show message about how to assign the data to a variable
#' @noRd
show_assignment_message <- function(suggested_name, data) {
  if (interactive() && !is.null(suggested_name)) {
    data_type <- if (inherits(data, "data.table")) {
      "data.table"
    } else if (inherits(data, "tbl_df")) {
      "tibble"
    } else {
      "data.frame"
    }
    
    n_rows <- nrow(data)
    n_cols <- ncol(data)
    
    cat("\n")
    cat("=== Data Imported Successfully ===\n")
    cat("Type: ", data_type, "\n", sep = "")
    cat("Dimensions: ", n_rows, " rows x ", n_cols, " columns\n", sep = "")
    cat("\n")
    cat("To use this data, assign it to a variable:\n")
    cat("  ", suggested_name, " <- read_ccsr(...)\n", sep = "")
    cat("\n")
    cat("Then you can use it:\n")
    cat("  head(", suggested_name, ")\n", sep = "")
    cat("  nrow(", suggested_name, ")\n", sep = "")
    cat("  # Or use with dplyr, data.table, etc.\n")
    cat("\n")
  }
}
