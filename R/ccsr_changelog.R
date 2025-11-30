#' Get CCSR Change Log
#'
#' Retrieves and displays the change log for CCSR versions. The change log
#' documents updates, additions, and modifications to CCSR categories across
#' different versions.
#'
#' @param version Character string specifying the CCSR version. Use "latest"
#'   (default) to get the change log for the most recent version, or specify a
#'   version like "v2026.1", "v2025.1", etc.
#' @param type Character string specifying the type of CCSR. Must be one of:
#'   "diagnosis" (or "dx") for ICD-10-CM diagnosis codes, or "procedure" (or
#'   "pr") for ICD-10-PCS procedure codes. Default is "diagnosis".
#' @param format Character string specifying the output format. Options:
#'   "read" (default) - Downloads and reads the Excel file as a data table/tibble (requires `readxl` package)
#'   "text" - Returns change log information as text
#'   "url" - Returns the URL to the change log document
#'   "download" - Downloads and returns the change log file path
#'   "view" - Downloads and opens the change log file in the default viewer
#'   "extract" - Attempts to extract text from the file (requires `pdftools` for PDF or `readxl` for Excel)
#'
#' @return Depending on `format`:
#'   - "read" (default): A tibble or data.table containing the change log data (if Excel file)
#'   - "text": Character string with change log information
#'   - "url": Character string with URL to change log
#'   - "download": Character string with path to downloaded file
#'   - "view": Opens the file and returns the file path (invisibly)
#'   - "extract": Character string with extracted text from file
#'
#' @param as_data_table Logical. If TRUE, returns a `data.table` instead of a tibble.
#'   Only used when `format = "read"`. If NULL (default), prompts the user interactively
#'   to choose (only in interactive sessions). In non-interactive sessions, defaults to FALSE.
#'
#' @details
#' CCSR change logs document:
#' - New CCSR categories added
#' - Categories that were removed or merged
#' - Changes to category descriptions
#' - Updates to ICD-10 code mappings
#' - Version-specific notes and improvements
#'
#' Change logs are typically available as PDF or text documents on the HCUP
#' website. This function attempts to locate and retrieve them.
#'
#' @examples
#' \dontrun{
#' # Get latest change log URL
#' changelog_url <- ccsr_changelog(format = "url")
#'
#' # Get change log information
#' changelog_info <- ccsr_changelog(version = "v2026.1", format = "text")
#'
#' # Download change log file
#' changelog_file <- ccsr_changelog(version = "v2025.1", format = "download")
#'
#' # View change log in default PDF viewer
#' ccsr_changelog(version = "v2026.1", format = "view")
#'
#' # Extract text from change log PDF (requires pdftools package)
#' changelog_text <- ccsr_changelog(version = "v2026.1", format = "extract")
#' cat(changelog_text)
#' }
#'
#' @importFrom httr2 request req_timeout req_user_agent req_perform resp_body_string resp_body_raw
#' @importFrom xml2 read_html xml_find_all xml_attr xml_text
#' @importFrom readxl read_excel excel_sheets
#' @export
ccsr_changelog <- function(version = "latest",
                          type = "diagnosis",
                          format = "read",
                          as_data_table = NULL) {
  
  # Validate inputs
  type <- tolower(type)
  if (type %in% c("dx", "diagnosis")) {
    type <- "diagnosis"
  } else if (type %in% c("pr", "procedure")) {
    type <- "procedure"
  } else {
    stop("`type` must be one of: 'diagnosis'/'dx' or 'procedure'/'pr'")
  }
  
  if (!format %in% c("text", "url", "download", "view", "extract", "read")) {
    stop("`format` must be one of: 'text', 'url', 'download', 'view', 'extract', or 'read'")
  }
  
  # Get version (use internal function from download_ccsr.R)
  if (version == "latest") {
    # Use the internal get_latest_version function
    version <- get_latest_version(type)
  }
  
  # Validate version format
  if (!grepl("^v\\d{4}[-.]\\d+$", version)) {
    stop("`version` must be in format 'vYYYY.N' or 'vYYYY-N' (e.g., 'v2026.1')")
  }
  
  # Convert version format for matching
  # Version format: v2026.1 -> v20261 (for filename matching)
  version_compact <- gsub("[^0-9]", "", version)
  version_compact <- paste0("v", version_compact)
  
  # Base URL for CCSR resources
  base_url <- "https://hcup-us.ahrq.gov/toolssoftware/ccsr/"
  
  # Dynamically discover change log files from HCUP website
  changelog_urls <- character()
  
  # Try to fetch from CCSR main page and archive page
  urls_to_check <- c(
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_refined.jsp",
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp"
  )
  
  # Determine prefix for file matching
  if (type == "diagnosis") {
    prefix <- "DXCCSR"
  } else {
    prefix <- "PRCCSR"
  }
  
  # Try each URL to find change log links
  for (check_url in urls_to_check) {
    if (length(changelog_urls) > 0) break
    
    tryCatch({
      resp <- httr2::request(check_url) |>
        httr2::req_user_agent("HCUPtools R package") |>
        httr2::req_timeout(30) |>
        httr2::req_perform()
      
      html_content <- httr2::resp_body_string(resp)
      doc <- xml2::read_html(html_content)
      
      # Find all links
      links <- xml2::xml_find_all(doc, "//a[@href]")
      hrefs <- xml2::xml_attr(links, "href")
      
      # Filter for change log links (Excel or PDF files with ChangeLog in name)
      changelog_candidates <- grep(
        paste0(".*", prefix, ".*[Cc]hange.*[Ll]og.*\\.(xlsx|pdf)"),
        hrefs,
        ignore.case = TRUE,
        value = TRUE
      )
      
      if (length(changelog_candidates) > 0) {
        # If interactive and user might want to choose, collect all change logs
        # Otherwise, match change logs where the requested version appears
        if (interactive()) {
          # In interactive mode, collect all change logs for this type
          # User can choose which one they want
          matching_links <- changelog_candidates
        } else {
          # Non-interactive: match change logs where the requested version appears
          # Change logs are typically in range format: DXCCSR-ChangeLog-v20251-v20261.xlsx
          # The requested version (e.g., v2026.1) should match the end of the range (v20261)
          matching_links <- character()
          
          for (link in changelog_candidates) {
            # Check if the version (in compact format) appears at the end of the filename
            # This handles range formats like v20251-v20261 where v2026.1 -> v20261
            if (grepl(paste0("-", version_compact, "\\.(xlsx|pdf)$"), link, ignore.case = TRUE)) {
              matching_links <- c(matching_links, link)
            }
            # Also check for exact version match anywhere in filename
            else if (grepl(version_compact, link, ignore.case = TRUE)) {
              matching_links <- c(matching_links, link)
            }
            # Also check for version with dots/hyphens
            else if (grepl(gsub("\\.", "-", version), link, ignore.case = TRUE)) {
              matching_links <- c(matching_links, link)
            }
          }
        }
        
        if (length(matching_links) > 0) {
          # Make all URLs absolute
          for (link in matching_links) {
            if (!grepl("^https?://", link)) {
              if (grepl("^/", link)) {
                absolute_url <- paste0("https://hcup-us.ahrq.gov", link)
              } else {
                absolute_url <- paste0(base_url, link)
              }
            } else {
              absolute_url <- link
            }
            changelog_urls <- c(changelog_urls, absolute_url)
          }
          # Remove duplicates
          changelog_urls <- unique(changelog_urls)
        }
      }
    }, error = function(e) {
      # Continue to next URL
    })
  }
  
  # Always try direct file patterns to find change logs that might not be on archive page
  # This ensures we find the latest change logs even if they're not yet linked on the archive page
  # Also try range formats (e.g., v20251-v20261 for v2026.1)
  # We do this even if we found some URLs, to ensure we have all available options
  # Generate possible file patterns based on known naming conventions
  # Format: DXCCSR-ChangeLog-v20251-v20261.xlsx (range) or DXCCSR-ChangeLog-v20261.xlsx (single version)
  version_url <- gsub("\\.", "-", version)
  
  # For range formats, we need to find the previous version
  # Change logs show changes FROM previous version TO requested version
  # e.g., DXCCSR-ChangeLog-v20251-v20261.xlsx shows changes from v2025.1 to v2026.1
  # So if requesting v2026.1, we look for a change log ending with v20261
  # Extract year and minor version to construct previous version
  version_num <- gsub("[^0-9]", "", version)
  if (nchar(version_num) >= 5) {
    year <- as.numeric(substr(version_num, 1, 4))
    minor <- as.numeric(substr(version_num, 5, nchar(version_num)))
    
    # Try previous version for range format
    if (minor > 1) {
      prev_version_compact <- paste0("v", year, sprintf("%02d", minor - 1))
    } else if (year > 2019) {
      # Previous year, last minor version (assume .1, but could check)
      prev_version_compact <- paste0("v", year - 1, "1")
    } else {
      prev_version_compact <- NULL
    }
  } else {
    prev_version_compact <- NULL
  }
  
  file_patterns <- c(
    # Range format Excel files (preferred): DXCCSR-ChangeLog-v20251-v20261.xlsx
    # This shows changes TO the requested version
    if (!is.null(prev_version_compact)) {
      paste0(prefix, "-ChangeLog-", prev_version_compact, "-", version_compact, ".xlsx")
    } else NULL,
    # Also try with different separators
    if (!is.null(prev_version_compact)) {
      paste0(prefix, "_ChangeLog_", prev_version_compact, "_", version_compact, ".xlsx")
    } else NULL,
    # Single version Excel files (if they exist)
    paste0(prefix, "-ChangeLog-", version_compact, ".xlsx"),
    paste0(prefix, "-ChangeLog-", version_url, ".xlsx"),
    paste0(prefix, "_ChangeLog_", version_compact, ".xlsx"),
    paste0(prefix, "_ChangeLog_", version_url, ".xlsx"),
    # PDF files
    paste0(prefix, "-", version_url, "_ChangeLog.pdf"),
    paste0(prefix, "_", version_url, "_ChangeLog.pdf"),
    paste0(prefix, "-", version_url, "-ChangeLog.pdf"),
    paste0(prefix, "_", version_url, "-ChangeLog.pdf")
  )
  
  # Remove NULL entries
  file_patterns <- file_patterns[!sapply(file_patterns, is.null)]
  
  for (pattern in file_patterns) {
    test_url <- paste0(base_url, pattern)
    
    # Test if URL exists with a HEAD request
    url_exists <- tryCatch({
      resp <- httr2::request(test_url) |>
        httr2::req_method("HEAD") |>
        httr2::req_user_agent("HCUPtools R package") |>
        httr2::req_timeout(5) |>
        httr2::req_perform()
      
      status <- httr2::resp_status(resp)
      status %in% c(200, 302, 301, 303)
    }, error = function(e) FALSE)
    
    if (url_exists) {
      changelog_urls <- c(changelog_urls, test_url)
      # If we found a match and we're not in interactive mode, we can break early
      # In interactive mode, collect all possible options
      if (!interactive() && length(changelog_urls) > 0) {
        break
      }
    }
  }
  # Remove duplicates
  changelog_urls <- unique(changelog_urls)
  
  # If multiple change logs found, let user choose interactively
  changelog_url <- NULL
  if (length(changelog_urls) > 0 && interactive()) {
    # In interactive mode, always show menu if there are multiple options
    # If only one, still show it so user can see what was selected
    if (length(changelog_urls) > 1) {
      changelog_url <- select_changelog_interactive(changelog_urls, version, type)
    } else {
      # Only one option, but show it to user and confirm
      message("Found 1 change log file. Using: ", basename(changelog_urls[1]))
      changelog_url <- changelog_urls[1]
    }
  } else if (length(changelog_urls) == 1) {
    # Non-interactive: use the single match
    changelog_url <- changelog_urls[1]
  } else if (length(changelog_urls) > 1) {
    # Non-interactive: use first (prefer Excel)
    excel_urls <- grep("\\.xlsx", changelog_urls, ignore.case = TRUE, value = TRUE)
    if (length(excel_urls) > 0) {
      changelog_url <- excel_urls[1]
    } else {
      changelog_url <- changelog_urls[1]
    }
  }
  
  # Return based on format
  if (format == "url") {
    if (is.null(changelog_url)) {
      warning("Could not determine change log URL. Returning generic URL.")
      return(paste0(base_url, "ccsr_archive.jsp"))
    }
    return(changelog_url)
  }
  
  # Helper function to download the change log file (PDF or Excel)
  download_changelog_file <- function(url) {
    if (is.null(url)) {
      stop("Could not locate change log file for this version. ",
           "Change logs may not be available for all versions. ",
           "Try visiting the HCUP CCSR archive page: ",
           "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp")
    }
    
    # Download to cache directory
    cache_dir <- file.path(tempdir(), "HCUPtools_cache")
    if (!dir.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    
    dest_file <- file.path(cache_dir, basename(url))
    
    # Check if already cached
    if (file.exists(dest_file)) {
      message("Using cached change log: ", dest_file)
      return(dest_file)
    }
    
    tryCatch({
      resp <- httr2::request(url) |>
        httr2::req_user_agent("HCUPtools R package") |>
        httr2::req_timeout(60) |>
        httr2::req_perform()
      
      httr2::resp_body_raw(resp) |>
        writeBin(dest_file)
      
      message("Change log downloaded to: ", dest_file)
      return(dest_file)
    }, error = function(e) {
      stop("Failed to download change log: ", conditionMessage(e),
           "\nTry accessing the URL directly: ", url)
    })
  }
  
  if (format == "download") {
    return(download_changelog_file(changelog_url))
  }
  
  if (format == "view") {
    if (is.null(changelog_url)) {
      stop("Could not locate change log file for this version. ",
           "Change logs may not be available for all versions. ",
           "Try visiting the HCUP CCSR archive page: ",
           "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp")
    }
    
    changelog_file <- download_changelog_file(changelog_url)
    
    # Determine file type and open appropriately
    is_pdf <- grepl("\\.pdf$", changelog_file, ignore.case = TRUE)
    is_excel <- grepl("\\.xlsx?$", changelog_file, ignore.case = TRUE)
    
    if (is_pdf) {
      # Open PDF in default viewer
      if (.Platform$OS.type == "windows") {
        shell.exec(changelog_file)
      } else if (Sys.info()["sysname"] == "Darwin") {
        system(paste("open", shQuote(changelog_file)))
      } else {
        # Linux
        system(paste("xdg-open", shQuote(changelog_file)))
      }
      message("Change log PDF opened in default viewer")
    } else if (is_excel) {
      # Open Excel file in default application
      if (.Platform$OS.type == "windows") {
        shell.exec(changelog_file)
      } else if (Sys.info()["sysname"] == "Darwin") {
        system(paste("open", shQuote(changelog_file)))
      } else {
        # Linux
        system(paste("xdg-open", shQuote(changelog_file)))
      }
      message("Change log Excel file opened in default application")
    } else {
      # Unknown file type, try to open anyway
      if (.Platform$OS.type == "windows") {
        shell.exec(changelog_file)
      } else if (Sys.info()["sysname"] == "Darwin") {
        system(paste("open", shQuote(changelog_file)))
      } else {
        system(paste("xdg-open", shQuote(changelog_file)))
      }
      message("Change log file opened in default application")
    }
    
    return(invisible(changelog_file))
  }
  
  if (format == "extract") {
    if (is.null(changelog_url)) {
      stop("Could not locate change log file for this version. ",
           "Change logs may not be available for all versions. ",
           "Try visiting the HCUP CCSR archive page: ",
           "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp")
    }
    
    changelog_file <- download_changelog_file(changelog_url)
    
    # Determine file type
    is_pdf <- grepl("\\.pdf$", changelog_file, ignore.case = TRUE)
    is_excel <- grepl("\\.xlsx?$", changelog_file, ignore.case = TRUE)
    
    if (is_pdf) {
      # Check if pdftools is available
      if (!requireNamespace("pdftools", quietly = TRUE)) {
        stop("Package 'pdftools' is required for PDF text extraction. ",
             "Install it with: install.packages('pdftools')\n",
             "Alternatively, use format = 'view' to open the file, or format = 'download' to save it.")
      }
      
      tryCatch({
        # Extract text from PDF
        pdf_text <- pdftools::pdf_text(changelog_file)
        extracted_text <- paste(pdf_text, collapse = "\n\n")
        
        message("Text extracted from change log PDF")
        return(extracted_text)
      }, error = function(e) {
        stop("Failed to extract text from PDF: ", conditionMessage(e),
             "\nThe PDF may be image-based or corrupted. ",
             "Try format = 'view' to open it, or format = 'download' to save it.")
      })
    } else if (is_excel) {
      # For Excel files, read and convert to text representation
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop("Package 'readxl' is required for Excel file extraction. ",
             "Install it with: install.packages('readxl')\n",
             "Alternatively, use format = 'view' to open the file, or format = 'download' to save it.")
      }
      
      tryCatch({
        # Read all sheets from Excel file
        sheet_names <- readxl::excel_sheets(changelog_file)
        extracted_text <- character()
        
        for (sheet in sheet_names) {
          sheet_data <- readxl::read_excel(changelog_file, sheet = sheet, .name_repair = "minimal")
          extracted_text <- c(extracted_text, 
                             paste0("\n=== Sheet: ", sheet, " ===\n"),
                             utils::capture.output(print(sheet_data)))
        }
        
        result <- paste(extracted_text, collapse = "\n")
        message("Content extracted from change log Excel file (", length(sheet_names), " sheet(s))")
        return(result)
      }, error = function(e) {
        stop("Failed to extract content from Excel file: ", conditionMessage(e),
             "\nTry format = 'view' to open it, or format = 'download' to save it.")
      })
    } else {
      stop("Unsupported file type for text extraction. ",
           "Only PDF and Excel files are supported. ",
           "Use format = 'view' to open the file, or format = 'download' to save it.")
    }
  }
  
  if (format == "read") {
    if (is.null(changelog_url)) {
      stop("Could not locate change log file for this version. ",
           "Change logs may not be available for all versions. ",
           "Try visiting the HCUP CCSR archive page: ",
           "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp")
    }
    
    changelog_file <- download_changelog_file(changelog_url)
    
    # Check if it's an Excel file
    is_excel <- grepl("\\.xlsx?$", changelog_file, ignore.case = TRUE)
    if (!is_excel) {
      stop("The 'read' format only works with Excel files. ",
           "This change log is a PDF file. ",
           "Use format = 'view' to open it, format = 'download' to save it, ",
           "or format = 'extract' to extract text.")
    }
    
    # Check if readxl is available
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required to read Excel files. ",
           "Install it with: install.packages('readxl')\n",
           "Alternatively, use format = 'view' to open the file, or format = 'download' to save it.")
    }
    
    # Handle as_data_table parameter
    if (is.null(as_data_table)) {
      # Check if data.table is available
      has_data_table <- requireNamespace("data.table", quietly = TRUE)
      
      if (interactive() && has_data_table) {
        cat("\nWould you like to import as a data.table? (faster for large datasets)\n")
        cat("  [1] Yes (data.table)\n")
        cat("  [2] No (tibble/data.frame) - default\n")
        cat("Enter choice (1 or 2, or press Enter for default): ")
        
        choice <- readline()
        choice <- trimws(choice)
        
        as_data_table <- (choice == "1" || tolower(choice) == "y" || tolower(choice) == "yes")
      } else {
        as_data_table <- FALSE
      }
    }
    
    tryCatch({
      # Read the first sheet (change logs typically have one main sheet)
      sheet_names <- readxl::excel_sheets(changelog_file)
      
      if (length(sheet_names) == 0) {
        stop("No sheets found in the Excel file.")
      }
      
      # Read the first sheet (or let user choose if multiple)
      if (length(sheet_names) == 1) {
        data <- readxl::read_excel(changelog_file, sheet = 1, .name_repair = "minimal")
      } else if (interactive()) {
        # Multiple sheets - let user choose
        cat("\n=== Available Sheets ===\n")
        for (i in seq_along(sheet_names)) {
          cat(sprintf("%2d. %s\n", i, sheet_names[i]))
        }
        cat("\nSelect a sheet (enter number, or press Enter for first sheet): ")
        selection <- readline()
        selection <- trimws(selection)
        
        if (selection == "" || is.na(as.integer(selection))) {
          sheet_idx <- 1
        } else {
          sheet_idx <- as.integer(selection)
          if (is.na(sheet_idx) || sheet_idx < 1 || sheet_idx > length(sheet_names)) {
            warning("Invalid selection. Using first sheet.")
            sheet_idx <- 1
          }
        }
        data <- readxl::read_excel(changelog_file, sheet = sheet_idx, .name_repair = "minimal")
      } else {
        # Non-interactive: use first sheet
        data <- readxl::read_excel(changelog_file, sheet = 1, .name_repair = "minimal")
      }
      
      # Convert to data.table if requested
      if (as_data_table) {
        data <- data.table::as.data.table(data)
      }
      
      message("Change log read successfully (", nrow(data), " rows, ", ncol(data), " columns)")
      return(data)
    }, error = function(e) {
      stop("Failed to read change log Excel file: ", conditionMessage(e),
           "\nTry format = 'view' to open it, or format = 'download' to save it.")
    })
  }
  
  # Format == "text"
  if (is.null(changelog_url)) {
    return(paste0(
      "Change log for CCSR ", type, " version ", version, ".\n",
      "Could not locate change log file for this version.\n",
      "Please visit the HCUP CCSR archive page for change log information:\n",
      "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp\n\n",
      "Note: Change logs may not be available for all versions, or may be ",
      "located on different pages. Try checking the archive page directly."
    ))
  }
  
  # For text format, return URL and instructions
  file_type <- if (grepl("\\.xlsx?$", changelog_url, ignore.case = TRUE)) {
    "Excel file"
  } else if (grepl("\\.pdf$", changelog_url, ignore.case = TRUE)) {
    "PDF file"
  } else {
    "file"
  }
  
  return(paste0(
    "Change log for CCSR ", type, " version ", version, ".\n",
    "URL: ", changelog_url, "\n",
    "File type: ", file_type, "\n\n",
    "To view the change log:\n",
    "  - Use format = 'view' to open in default application\n",
    "  - Use format = 'download' to save the file\n",
    "  - Use format = 'extract' to extract text/content\n",
    "  - Or visit the URL directly in your browser"
  ))
}

#' Interactive selection of change log file
#' @noRd
select_changelog_interactive <- function(changelog_urls, version, type) {
  if (length(changelog_urls) == 0) {
    return(NULL)
  }
  
  if (length(changelog_urls) == 1) {
    return(changelog_urls[1])
  }
  
  # Parse file names to extract version information
  file_info <- lapply(changelog_urls, function(url) {
    filename <- basename(url)
    
    # Extract version range from filename (e.g., v20251-v20261)
    version_match <- regmatches(filename, regexpr("v\\d+-v\\d+", filename))
    if (length(version_match) > 0) {
      version_range <- version_match[1]
      # Extract the end version for sorting (e.g., v20261 from v20251-v20261)
      end_version <- regmatches(version_range, regexpr("v\\d+$", version_range))
      if (length(end_version) > 0) {
        # Convert to numeric for sorting (e.g., v20261 -> 20261)
        version_num <- as.numeric(gsub("v", "", end_version[1]))
      } else {
        version_num <- 0
      }
    } else {
      # Try single version
      version_match <- regmatches(filename, regexpr("v\\d+", filename))
      if (length(version_match) > 0) {
        version_range <- version_match[1]
        version_num <- as.numeric(gsub("v", "", version_range))
      } else {
        version_range <- "Unknown"
        version_num <- 0
      }
    }
    
    # Determine file type
    file_type <- if (grepl("\\.xlsx", filename, ignore.case = TRUE)) {
      "Excel"
    } else if (grepl("\\.pdf", filename, ignore.case = TRUE)) {
      "PDF"
    } else {
      "Unknown"
    }
    
    list(
      url = url,
      filename = filename,
      version_range = version_range,
      file_type = file_type,
      version_num = version_num
    )
  })
  
  # Sort by version number (most recent first - descending order)
  version_nums <- sapply(file_info, function(x) x$version_num)
  file_info <- file_info[order(version_nums, decreasing = TRUE)]
  
  # Show interactive menu
  cat("\n=== Available Change Log Files ===\n\n")
  for (i in seq_along(file_info)) {
    info <- file_info[[i]]
    cat(sprintf("%2d. %s\n", i, info$filename))
    cat(sprintf("    Version range: %s | Type: %s\n", 
                info$version_range, info$file_type))
    cat("\n")
  }
  
  cat("Select a change log file (enter number): ")
  selection <- readline()
  selection <- as.integer(selection)
  
  if (is.na(selection) || selection < 1 || selection > length(file_info)) {
    stop("Invalid selection. Please run the function again and select a valid number.")
  }
  
  return(file_info[[selection]]$url)
}

