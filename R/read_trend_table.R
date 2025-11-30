#' Read HCUP Summary Trend Table from Disk
#'
#' Reads a previously downloaded HCUP Summary Trend Table Excel file from disk.
#' If no file path is provided, automatically finds and reads cached files from
#' `download_trend_tables()`, with an interactive menu to select from available
#' tables.
#'
#' @param file_path Optional character string, path to a trend table Excel file (.xlsx).
#'   If NULL (default), automatically searches the cache directory for files
#'   downloaded via `download_trend_tables()` and shows an interactive menu.
#' @param table_id Optional character string, table ID (e.g., "1", "2a", "2b") to
#'   read from cache. Only used when `file_path` is NULL. If both are NULL, shows
#'   interactive menu.
#' @param sheet Character string or integer specifying which sheet to read. If
#'   NULL (default), shows an interactive menu to select a sheet (in interactive sessions),
#'   or automatically selects the "National" sheet (or first data sheet) in non-interactive sessions.
#'   Common sheet names include "National", "Regional", "State", etc.
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
#'   result: `my_data <- read_trend_table()`. If NULL (default), a name is
#'   suggested based on the table ID and sheet.
#'
#' @return A tibble (or data.table if `as_data_table = TRUE`) containing the
#'   trend table data. Tibbles are data frames and can be used with all
#'   standard R data frame operations, including `dplyr`, `data.table`, and
#'   base R functions.
#'
#' @note To use the data, assign it to a variable:
#'   `my_data <- read_trend_table()`. The `name` parameter is only for display
#'   purposes and does not automatically assign the data.
#'
#' @details
#' HCUP Summary Trend Tables are Excel files with multiple sheets containing
#' data at different geographic levels (National, Regional, State). Use the
#' `sheet` parameter to specify which sheet to read, or call the function
#' multiple times with different sheets.
#'
#' When `file_path` is NULL, the function automatically searches the cache
#' directory (`tempdir()`) for files matching the pattern `HCUP_SummaryTrendTables_*.xlsx`.
#' If multiple files are found, an interactive menu is displayed for selection.
#'
#' To see available sheets, use `list_trend_table_sheets()`.
#'
#' @examples
#' \dontrun{
#' # Automatically read from cache (shows menu if multiple files)
#' # Assign to a variable to use the data
#' national_data <- read_trend_table()
#'
#' # Read specific table from cache with suggested name
#' table_2a <- read_trend_table(table_id = "2a", name = "table_2a")
#'
#' # Read from a specific file path (manual)
#' national_data <- read_trend_table("path/to/HCUP_SummaryTrendTables_T2a.xlsx")
#'
#' # Read a specific sheet with custom name
#' state_data <- read_trend_table(
#'   "path/to/HCUP_SummaryTrendTables_T2a.xlsx",
#'   sheet = "State",
#'   name = "state_data"
#' )
#'
#' # List available sheets first
#' sheets <- list_trend_table_sheets("path/to/HCUP_SummaryTrendTables_T2a.xlsx")
#' print(sheets)
#'
#' # Use the data after assignment
#' head(national_data)
#' nrow(national_data)
#' }
#'
#' @importFrom readxl read_excel excel_sheets
#' @importFrom tibble as_tibble
#' @export
read_trend_table <- function(file_path = NULL,
                            table_id = NULL,
                            sheet = NULL,
                            clean_names = TRUE,
                            as_data_table = NULL,
                            name = NULL) {
  
  # Determine suggested variable name early (before prompts)
  suggested_name <- determine_trend_table_name(name, table_id, sheet)
  
  # Handle interactive prompt for as_data_table FIRST (before file selection)
  # Show the tip along with the data.table question
  if (is.null(as_data_table)) {
    as_data_table <- prompt_for_data_table(suggested_name, "read_trend_table")
  }
  
  # Check if readxl is available
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required for reading Excel files. ",
         "Install it with: install.packages('readxl')")
  }
  
  # If no file_path provided, automatically find cached file or show interactive menu
  if (is.null(file_path)) {
    cached_files <- list_cached_trend_table_files()
    
    if (length(cached_files) == 0) {
      stop("No cached trend table files found. ",
           "Please download a file first using `download_trend_tables()` ",
           "or provide a `file_path`.")
    }
    
    # If table_id is specified, try to find matching file
    if (!is.null(table_id)) {
      table_id <- tolower(as.character(table_id))
      matching_files <- cached_files[sapply(cached_files, function(f) {
        grepl(paste0("T", table_id, "\\.xlsx"), f$basename, ignore.case = TRUE)
      })]
      
      if (length(matching_files) > 0) {
        file_path <- matching_files[[1]]$path
        message("Reading cached file: ", basename(file_path))
      } else {
        stop("No cached file found for table_id '", table_id, 
             "'. Available files: ", 
             paste(sapply(cached_files, function(f) f$basename), collapse = ", "))
      }
    } else {
      # Multiple files - show interactive menu
      if (length(cached_files) == 1) {
        file_path <- cached_files[[1]]$path
        message("Reading cached file: ", basename(file_path))
      } else {
        file_path <- select_cached_trend_table_interactive(cached_files)
      }
    }
  }
  
  # Validate file path
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  # Check if it's an Excel file
  if (!grepl("\\.xlsx?$", file_path, ignore.case = TRUE)) {
    stop("File must be an Excel file (.xlsx or .xls)")
  }
  
  # Get all sheet names
  all_sheets <- readxl::excel_sheets(file_path)
  
  # Identify metadata/disclaimer sheets to skip
  metadata_patterns <- c(
    "data.*use.*agreement",
    "disclaimer",
    "read.*me",
    "instructions",
    "notes",
    "metadata",
    "end.*of.*content"
  )
  
  is_metadata <- sapply(all_sheets, function(s) {
    any(sapply(metadata_patterns, function(p) {
      grepl(p, s, ignore.case = TRUE)
    }))
  })
  
  # Find data sheets (common names: National, Regional, State, etc.)
  data_sheets <- all_sheets[!is_metadata]
  
  # If sheet is specified, use it
  if (!is.null(sheet)) {
    if (is.character(sheet)) {
      if (!sheet %in% all_sheets) {
        stop("Sheet '", sheet, "' not found. Available sheets: ", 
             paste(all_sheets, collapse = ", "))
      }
      selected_sheet <- sheet
    } else if (is.numeric(sheet)) {
      if (sheet < 1 || sheet > length(all_sheets)) {
        stop("Sheet index ", sheet, " out of range. Available sheets: ", 
             length(all_sheets))
      }
      selected_sheet <- all_sheets[sheet]
    } else {
      stop("`sheet` must be a character string (sheet name) or integer (sheet index)")
    }
  } else {
    # No sheet specified - show interactive menu or auto-select
    if (interactive() && length(data_sheets) > 1) {
      # Show interactive menu for sheet selection
      selected_sheet <- select_trend_table_sheet_interactive(all_sheets, data_sheets, is_metadata)
    } else if (length(data_sheets) > 0) {
      # Non-interactive or single sheet: auto-select "National" or first data sheet
      if ("National" %in% data_sheets) {
        selected_sheet <- "National"
        message("Reading sheet: ", selected_sheet)
      } else {
        selected_sheet <- data_sheets[1]
        message("Reading sheet: ", selected_sheet)
      }
    } else {
      # Fallback: use first sheet if all are metadata
      selected_sheet <- all_sheets[1]
      warning("Could not identify data sheet. Using first sheet: ", selected_sheet)
    }
  }
  
  # Read the selected sheet
  data <- tryCatch({
    # Use "unique" name repair to handle empty column names
    # This will create unique names like "X1", "X2" for empty columns
    readxl::read_excel(file_path, sheet = selected_sheet, .name_repair = "unique")
  }, error = function(e) {
    stop("Failed to read Excel file: ", conditionMessage(e))
  })
  
  # Check if the sheet appears to be metadata (very few rows, mostly text)
  if (nrow(data) < 5) {
    # Check if it's mostly text/empty
    text_cols <- sapply(data, function(x) {
      if (is.character(x) || is.factor(x)) {
        sum(!is.na(x) & nchar(as.character(x)) > 50) / length(x)
      } else {
        0
      }
    })
    
    if (mean(text_cols) > 0.5) {
      warning("The selected sheet appears to be a metadata/disclaimer sheet. ",
              "Available data sheets: ", paste(data_sheets, collapse = ", "),
              ". Use `sheet` parameter to select a different sheet.")
    }
  }
  
  # Ensure it's a tibble with proper name repair (already done by read_excel, but ensure)
  if (!inherits(data, "tbl_df")) {
    data <- tibble::as_tibble(data, .name_repair = "unique")
  }
  
  # Clean column names if requested
  if (clean_names) {
    names(data) <- gsub("\\s+", "_", tolower(names(data)))
    names(data) <- gsub("[^a-z0-9_]", "", names(data))
  }
  
  # Convert to data.table if requested
  result <- convert_to_data_table_if_requested(data, as_data_table)
  
  # Show assignment message
  show_trend_table_assignment_message(suggested_name, result)
  
  return(result)
}

#' Determine suggested variable name for trend table data
#' @noRd
determine_trend_table_name <- function(name, table_id, sheet) {
  if (!is.null(name) && is.character(name) && length(name) == 1 && nchar(name) > 0) {
    # User provided a name, use it
    return(name)
  }
  
  # Generate suggested name based on table_id and sheet
  suggested <- "trend_table"
  
  if (!is.null(table_id)) {
    table_id_clean <- gsub("[^0-9a-z]", "", tolower(table_id))
    if (nchar(table_id_clean) > 0) {
      suggested <- paste0("table_", table_id_clean)
    }
  }
  
  if (!is.null(sheet)) {
    sheet_clean <- gsub("[^a-z0-9]", "", tolower(as.character(sheet)))
    if (nchar(sheet_clean) > 0) {
      suggested <- paste0(suggested, "_", sheet_clean)
    }
  }
  
  return(suggested)
}

#' Show message about how to assign the trend table data to a variable
#' @noRd
show_trend_table_assignment_message <- function(suggested_name, data) {
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
    cat("=== Trend Table Imported Successfully ===\n")
    cat("Type: ", data_type, "\n", sep = "")
    cat("Dimensions: ", n_rows, " rows x ", n_cols, " columns\n", sep = "")
    cat("\n")
    cat("To use this data, assign it to a variable:\n")
    cat("  ", suggested_name, " <- read_trend_table(...)\n", sep = "")
    cat("\n")
    cat("Then you can use it:\n")
    cat("  head(", suggested_name, ")\n", sep = "")
    cat("  nrow(", suggested_name, ")\n", sep = "")
    cat("  # Or use with dplyr, data.table, etc.\n")
    cat("\n")
  }
}

#' List Available Sheets in Trend Table
#'
#' Lists all available sheets in a HCUP Summary Trend Table Excel file.
#'
#' @param file_path Character string, path to a trend table Excel file (.xlsx).
#'
#' @return A character vector of sheet names.
#'
#' @examples
#' \dontrun{
#' sheets <- list_trend_table_sheets("path/to/HCUP_SummaryTrendTables_T2a.xlsx")
#' print(sheets)
#' }
#'
#' @importFrom readxl excel_sheets
#' @export
list_trend_table_sheets <- function(file_path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required. Install it with: install.packages('readxl')")
  }
  
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  if (!grepl("\\.xlsx?$", file_path, ignore.case = TRUE)) {
    stop("File must be an Excel file (.xlsx or .xls)")
  }
  
  sheets <- readxl::excel_sheets(file_path)
  return(sheets)
}

#' List all cached trend table files
#' @noRd
list_cached_trend_table_files <- function() {
  cache_dir <- tempdir()
  
  # Look for trend table Excel files
  all_files <- list.files(cache_dir, 
                          pattern = "HCUP_SummaryTrendTables_.*\\.xlsx$", 
                          full.names = TRUE, 
                          ignore.case = TRUE)
  
  if (length(all_files) == 0) {
    return(list())
  }
  
  # Parse file information
  files_info <- list()
  for (file in all_files) {
    basename_file <- basename(file)
    
    # Extract table ID from filename (e.g., "T1", "T2a", "T2b")
    table_id_match <- regmatches(basename_file, 
                                regexpr("T([0-9]+[a-z]?)", basename_file, 
                                       ignore.case = TRUE))
    table_id <- if (length(table_id_match) > 0) {
      tolower(sub("T", "", table_id_match, ignore.case = TRUE))
    } else {
      "unknown"
    }
    
    files_info[[length(files_info) + 1]] <- list(
      path = file,
      table_id = table_id,
      basename = basename_file
    )
  }
  
  # Sort by table ID
  table_ids_numeric <- sapply(files_info, function(f) {
    id <- f$table_id
    # Convert "2a" to "2.1", "2b" to "2.2", etc. for sorting
    if (grepl("[a-z]$", id)) {
      num_part <- as.numeric(gsub("[a-z]", "", id))
      letter_part <- match(sub("[0-9]+", "", id), letters)
      paste0(num_part, ".", letter_part)
    } else {
      paste0(id, ".0")
    }
  })
  
  sorted_idx <- order(as.numeric(gsub("\\..*", "", table_ids_numeric)),
                     as.numeric(gsub(".*\\.", "", table_ids_numeric)))
  files_info <- files_info[sorted_idx]
  
  return(files_info)
}

#' Interactive selection of cached trend table file
#' @noRd
select_cached_trend_table_interactive <- function(cached_files) {
  # Show interactive menu
  cat("\n=== Available Cached Trend Table Files ===\n\n")
  for (i in seq_along(cached_files)) {
    f <- cached_files[[i]]
    cat(sprintf("%2d. Table %s - %s\n", 
                i, 
                toupper(f$table_id),
                f$basename))
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
    # Non-interactive: return first file
    return(cached_files[[1]]$path)
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

#' Convert tibble to data.table if requested
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

#' Interactive selection of trend table sheet
#' @noRd
select_trend_table_sheet_interactive <- function(all_sheets, data_sheets, is_metadata) {
  if (length(data_sheets) == 0) {
    warning("No data sheets found. All sheets appear to be metadata.")
    return(all_sheets[1])
  }
  
  if (length(data_sheets) == 1) {
    message("Reading sheet: ", data_sheets[1])
    return(data_sheets[1])
  }
  
  # Show interactive menu
  cat("\n=== Available Sheets ===\n\n")
  
  # Show data sheets first (recommended)
  cat("Data Sheets (recommended):\n")
  data_sheet_indices <- which(all_sheets %in% data_sheets)
  for (i in seq_along(data_sheets)) {
    idx <- data_sheet_indices[i]
    cat(sprintf("%2d. %s", idx, data_sheets[i]))
    if (data_sheets[i] == "National") {
      cat(" (default)")
    }
    cat("\n")
  }
  
  # Show metadata sheets if any (not recommended)
  if (any(is_metadata)) {
    metadata_sheets <- all_sheets[is_metadata]
    cat("\nMetadata/Disclaimer Sheets (not recommended):\n")
    metadata_indices <- which(is_metadata)
    for (i in seq_along(metadata_sheets)) {
      idx <- metadata_indices[i]
      cat(sprintf("%2d. %s (metadata)\n", idx, metadata_sheets[i]))
    }
  }
  
  cat("\n")
  cat("Select a sheet (enter number, or press Enter for 'National'): ")
  
  selection <- readline()
  selection <- trimws(selection)
  
  if (selection == "") {
    # Default to National if available, otherwise first data sheet
    if ("National" %in% data_sheets) {
      return("National")
    } else {
      return(data_sheets[1])
    }
  }
  
  selection <- as.integer(selection)
  
  if (is.na(selection) || selection < 1 || selection > length(all_sheets)) {
    stop("Invalid selection. Please run the function again and select a valid number.")
  }
  
  selected_sheet <- all_sheets[selection]
  
  # Warn if selecting a metadata sheet
  if (is_metadata[selection]) {
    warning("You selected a metadata/disclaimer sheet. ",
            "This may not contain the actual trend table data. ",
            "Consider selecting a data sheet instead.")
  }
  
  return(selected_sheet)
}

