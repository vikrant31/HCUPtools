#' Download HCUP Summary Trend Tables
#'
#' Downloads HCUP Summary Trend Tables from the HCUP website. These tables provide
#' information on hospital utilization derived from HCUP databases, including trends
#' in inpatient and emergency department utilization.
#'
#' @param table_id Character string or numeric specifying which table to download.
#'   Can be:
#'   - A table number (e.g., "1", "2a", "6b", "11c") for specific tables
#'   - "all" to download all available tables as a ZIP file
#'   - NULL (default) to show an interactive menu for selecting a table (in interactive sessions),
#'     or return a list of available tables (in non-interactive sessions)
#' @param dest_dir Character string specifying the destination directory for the
#'   downloaded file(s). If NULL (default), files are saved to a temporary directory.
#' @param cache Logical. If TRUE (default), downloaded files are cached to avoid
#'   re-downloading on subsequent calls.
#'
#' @return If `table_id` is NULL and session is non-interactive, returns a data frame listing available tables.
#'   Otherwise, returns the path(s) to the downloaded file(s).
#'
#' @details
#' The HCUP Summary Trend Tables include information on:
#' - Overview of trends in inpatient and emergency department utilization
#' - All inpatient encounter types
#' - Inpatient encounter types (normal newborns, deliveries, elective/non-elective stays)
#' - Inpatient service lines (maternal/neonatal, mental health, injuries, surgeries, etc.)
#' - ED treat-and-release visits
#'
#' Each table is available as an Excel file with state-specific, region-specific,
#' and national statistics.
#'
#' The function automatically discovers available tables by scraping the HCUP website,
#' so it will automatically adapt to new tables or version changes.
#'
#' For more information, see:
#' https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp
#'
#' @examples
#' \dontrun{
#' # List available tables
#' available_tables <- download_trend_tables()
#' print(available_tables)
#'
#' # Download a specific table
#' table_path <- download_trend_tables("2a")
#'
#' # Download all tables
#' all_tables <- download_trend_tables("all")
#' }
#'
#' @importFrom httr2 request req_timeout req_user_agent req_perform resp_body_raw resp_body_string
#' @importFrom utils unzip
#' @importFrom tibble tibble
#' @importFrom xml2 read_html xml_find_all xml_attr xml_text
#' @importFrom dplyr mutate arrange
#' @importFrom rlang .data
#' @export
download_trend_tables <- function(table_id = NULL,
                                  dest_dir = NULL,
                                  cache = TRUE) {
  base_url <- "https://hcup-us.ahrq.gov/reports/trendtables/"
  
  # Get available tables dynamically from HCUP website
  available_tables <- get_available_trend_tables(base_url, cache)
  
  # If table_id is NULL, show interactive menu or return list
  if (is.null(table_id)) {
    if (interactive() && nrow(available_tables) > 0) {
      # Show interactive menu
      table_id <- select_trend_table_interactive(available_tables)
      if (is.null(table_id)) {
        # User cancelled or invalid selection
        return(available_tables)
      }
    } else {
      # Non-interactive: return list of available tables
      return(available_tables)
    }
  }
  
  # Convert to character and lowercase
  table_id <- tolower(as.character(table_id))
  
  # Handle "all" case - download ZIP file
  if (table_id == "all") {
    # Try to find the ZIP file URL dynamically
    zip_urls <- c(
      "https://hcup-us.ahrq.gov/reports/trendtables/HCUP_SummaryTrendTables_All.zip",
      "https://hcup-us.ahrq.gov/reports/trendtables/HCUP_SummaryTrendTables.zip"
    )
    
    # Test which URL exists
    zip_url <- NULL
    for (test_url in zip_urls) {
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
        zip_url <- test_url
        break
      }
    }
    
    if (is.null(zip_url)) {
      # ZIP file not available - offer to download all individual tables instead
      if (interactive()) {
        cat("\n")
        cat("The 'all tables' ZIP file is not available on the HCUP website.\n")
        cat("Would you like to download all individual tables instead?\n")
        cat("  [1] Yes - Download all ", nrow(available_tables), " tables\n", sep = "")
        cat("  [2] No - Cancel\n")
        cat("Enter choice (1 or 2, or press Enter to cancel): ")
        
        choice <- readline()
        choice <- trimws(choice)
        
        if (choice == "1" || tolower(choice) == "y" || tolower(choice) == "yes") {
          # Download all individual tables
          message("Downloading all ", nrow(available_tables), " individual tables...")
          message("This may take several minutes.")
          
          downloaded_files <- character()
          for (i in seq_len(nrow(available_tables))) {
            table_info <- available_tables[i, ]
            cat(sprintf("Downloading table %d/%d: %s...\n", 
                       i, nrow(available_tables), table_info$table_name))
            
            tryCatch({
              file_path <- download_trend_tables(
                table_id = table_info$table_id,
                dest_dir = dest_dir,
                cache = cache
              )
              downloaded_files <- c(downloaded_files, file_path)
            }, error = function(e) {
              warning("Failed to download table ", table_info$table_id, ": ", 
                     conditionMessage(e))
            })
          }
          
          message("\nDownload complete! ", length(downloaded_files), 
                 " table(s) downloaded successfully.")
          return(downloaded_files)
        } else {
          stop("Download cancelled.")
        }
      } else {
        stop("The 'all tables' ZIP file is not available on the HCUP website. ",
             "Please download individual tables using their table IDs. ",
             "Use download_trend_tables() to see available tables.")
      }
    }
    
    file_name <- basename(zip_url)
    
    if (is.null(dest_dir)) {
      dest_dir <- tempdir()
    }
    
    dest_file <- file.path(dest_dir, file_name)
    
    # Check cache if enabled
    if (cache && file.exists(dest_file)) {
      message("Using cached file: ", dest_file)
      return(dest_file)
    }
    
    message("Downloading all HCUP Summary Trend Tables...")
    message("This may take several minutes due to file size (~81 MB)")
    
    tryCatch({
      resp <- httr2::request(zip_url) |>
        httr2::req_timeout(300) |>
        httr2::req_user_agent("HCUPtools R package") |>
        httr2::req_perform()
      
      httr2::resp_body_raw(resp) |>
        writeBin(dest_file)
      
      message("Download complete: ", dest_file)
      return(dest_file)
    }, error = function(e) {
      stop("Failed to download trend tables: ", conditionMessage(e),
           "\nThe ZIP file may not be available. ",
           "Try downloading individual tables instead.")
    })
  }
  
  # Validate table_id
  if (!table_id %in% available_tables$table_id) {
    stop("Invalid table_id. Use download_trend_tables() to see available tables.")
  }
  
  # Get file name from available_tables (handles different naming patterns)
  table_info <- available_tables[available_tables$table_id == table_id, ]
  file_name <- table_info$file_name[1]
  url <- paste0(base_url, file_name)
  
  # Set destination directory
  if (is.null(dest_dir)) {
    dest_dir <- tempdir()
  }
  
  dest_file <- file.path(dest_dir, file_name)
  
  # Check cache if enabled
  if (cache && file.exists(dest_file)) {
    message("Using cached file: ", dest_file)
    return(dest_file)
  }
  
  # Get table name for message
  table_name <- table_info$table_name[1]
  message("Downloading: ", table_name)
  message("URL: ", url)
  
  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_timeout(120) |>
      httr2::req_user_agent("HCUPtools R package") |>
      httr2::req_perform()
    
    httr2::resp_body_raw(resp) |>
      writeBin(dest_file)
    
    message("Download complete: ", dest_file)
    return(dest_file)
  }, error = function(e) {
    stop("Failed to download table ", table_id, ": ", conditionMessage(e))
  })
}

#' Fetch available trend tables from HCUP website
#'
#' @param base_url Character string, base URL for trend tables
#' @param cache Logical, whether to use cached results
#' @return A tibble with table_id, table_name, and file_name columns
#'
#' @noRd
get_available_trend_tables <- function(base_url, cache = TRUE) {
  # Cache key for storing results
  cache_name <- "hcup_trend_tables_list"
  cache_path <- file.path(tempdir(), cache_name)
  
  # Check cache (valid for 24 hours)
  cached_tables <- NULL
  if (cache && file.exists(cache_path)) {
    cache_info <- file.info(cache_path)
    cache_age <- as.numeric(Sys.time() - cache_info$mtime, units = "hours")
    if (cache_age < 24) {
      tryCatch({
        cached_data <- readRDS(cache_path)
        if (inherits(cached_data, "data.frame") && 
            "table_id" %in% names(cached_data) && 
            "table_name" %in% names(cached_data)) {
          cached_tables <- cached_data
        }
      }, error = function(e) {
        # Cache file corrupted, will re-fetch
      })
    }
  }
  
  # If not cached, fetch from HCUP website
  if (is.null(cached_tables)) {
    url <- "https://hcup-us.ahrq.gov/reports/trendtables/summarytrendtables.jsp"
    
    tryCatch({
      resp <- httr2::request(url) |>
        httr2::req_user_agent("HCUPtools R package") |>
        httr2::req_timeout(30) |>
        httr2::req_perform()
      
      html_content <- httr2::resp_body_string(resp)
      doc <- xml2::read_html(html_content)
      
      # Find all links to Excel files
      links <- xml2::xml_find_all(doc, "//a[@href]")
      hrefs <- xml2::xml_attr(links, "href")
      link_texts <- xml2::xml_text(links)
      
      # Filter for trend table links (Excel files)
      trend_table_pattern <- "HCUP_SummaryTrendTables_T.*\\.xlsx"
      trend_table_links <- grep(trend_table_pattern, hrefs, value = TRUE, ignore.case = TRUE)
      trend_table_texts <- link_texts[grep(trend_table_pattern, hrefs, ignore.case = TRUE)]
      
      # Extract table IDs and names
      tables_list <- list()
      
      for (i in seq_along(trend_table_links)) {
        href <- trend_table_links[i]
        text <- trimws(trend_table_texts[i])
        
        # Extract table ID from filename (e.g., "T2a" -> "2a")
        table_id_match <- regmatches(href, regexpr("T([0-9]+[a-z]?)", href, ignore.case = TRUE))
        if (length(table_id_match) > 0) {
          table_id <- tolower(sub("T", "", table_id_match, ignore.case = TRUE))
          
          # Use link text as table name, or construct from filename if text is empty
          if (nchar(text) == 0 || text == href) {
            # Try to extract from href or use a generic name
            table_name <- paste("Table", toupper(table_id))
          } else {
            # Clean up table name - remove "Table X." prefix if present
            table_name <- gsub("^Table\\s+[0-9]+[a-z]?\\.\\s*", "", text, ignore.case = TRUE)
            table_name <- trimws(table_name)
            # If cleaning removed everything, use original text
            if (nchar(table_name) == 0) {
              table_name <- text
            }
          }
          
          tables_list[[length(tables_list) + 1]] <- list(
            table_id = table_id,
            table_name = table_name,
            file_name = basename(href)
          )
        }
      }
      
      # Also check for the "all" ZIP file
      zip_pattern <- "HCUP_SummaryTrendTables.*\\.zip"
      zip_links <- grep(zip_pattern, hrefs, value = TRUE, ignore.case = TRUE)
      if (length(zip_links) > 0) {
        # Use the first ZIP file found (usually the "all" file)
        zip_file <- basename(zip_links[1])
      } else {
        zip_file <- "HCUP_SummaryTrendTables_All.zip"
      }
      
      if (length(tables_list) > 0) {
        cached_tables <- dplyr::bind_rows(tables_list) |>
          dplyr::mutate(
            # Sort by numeric part first, then alphabetic
            sort_key = as.numeric(gsub("[^0-9]", "", .data$table_id)),
            sort_key2 = gsub("[0-9]", "", .data$table_id)
          ) |>
          dplyr::arrange(.data$sort_key, .data$sort_key2) |>
          dplyr::select(-.data$sort_key, -.data$sort_key2)
        
        # Cache the result
        tryCatch({
          saveRDS(cached_tables, cache_path)
        }, error = function(e) {
          # Cache save failed, continue without caching
        })
      } else {
        # Fallback: return empty tibble with expected structure
        cached_tables <- tibble::tibble(
          table_id = character(0),
          table_name = character(0),
          file_name = character(0)
        )
      }
    }, error = function(e) {
      warning("Could not fetch trend tables from HCUP website: ", 
              conditionMessage(e),
              ". Using fallback method.")
      # Fallback: return empty tibble
      cached_tables <- tibble::tibble(
        table_id = character(0),
        table_name = character(0),
        file_name = character(0)
      )
    })
  }
  
  return(cached_tables)
}

#' Interactive selection of trend table
#' @noRd
select_trend_table_interactive <- function(available_tables) {
  if (nrow(available_tables) == 0) {
    stop("No trend tables available.")
  }
  
  if (nrow(available_tables) == 1) {
    return(available_tables$table_id[1])
  }
  
  # Show interactive menu
  cat("\n=== Available HCUP Summary Trend Tables ===\n\n")
  for (i in seq_len(nrow(available_tables))) {
    table <- available_tables[i, ]
    cat(sprintf("%2d. [%s] %s\n", 
                i, 
                table$table_id,
                table$table_name))
  }
  cat("\n")
  cat("  [0] Download all tables (ZIP file - if available)\n")
  cat("\n")
  cat("Select a table (enter number, or 0 for all): ")
  
  selection <- readline()
  selection <- trimws(selection)
  
  if (selection == "" || is.na(as.integer(selection))) {
    return(NULL)
  }
  
  selection <- as.integer(selection)
  
  if (selection == 0) {
    return("all")
  }
  
  if (is.na(selection) || selection < 1 || selection > nrow(available_tables)) {
    stop("Invalid selection. Please run the function again and select a valid number.")
  }
  
  return(available_tables$table_id[selection])
}

