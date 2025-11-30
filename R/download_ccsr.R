#' Download CCSR Mapping Files from HCUP
#'
#' Downloads and loads Clinical Classifications Software Refined (CCSR) mapping
#' files directly from the Agency for Healthcare Research and Quality (AHRQ)
#' Healthcare Cost and Utilization Project (HCUP) website.
#'
#' @param type Character string specifying the type of CCSR file to download.
#'   Must be one of: "diagnosis" (or "dx") for ICD-10-CM diagnosis codes, or
#'   "procedure" (or "pr") for ICD-10-PCS procedure codes. Default is "diagnosis".
#' @param version Character string specifying the CCSR version to download.
#'   Use "latest" to download the most recent version, or specify a version
#'   like "v2026.1", "v2025.1", etc. Default is "latest".
#' @param cache Logical. If TRUE (default), the downloaded file is cached in
#'   a temporary directory to avoid re-downloading on subsequent calls.
#' @param clean_names Logical. If TRUE (default), column names are cleaned to
#'   follow R naming conventions (snake_case).
#'
#' @return A tibble containing the CCSR mapping data with the following columns:
#'   - For diagnosis files: ICD-10-CM code, CCSR category, default CCSR category,
#'     and clinical descriptions
#'   - For procedure files: ICD-10-PCS code, CCSR category, and descriptions
#'
#' @details
#' This function downloads CCSR mapping files directly from the HCUP website.
#' The package does not redistribute these files but facilitates access to the
#' official AHRQ data sources.
#'
#' The function handles:
#' - Automatic URL construction based on type and version
#' - ZIP file download and extraction
#' - Proper encoding of special characters
#' - Preservation of leading zeros in ICD-10 codes
#' - Conversion to tidy tibble format
#'
#' @examples
#' \dontrun{
#' # Download latest diagnosis CCSR mapping
#' dx_map <- download_ccsr("diagnosis")
#'
#' # Download specific version of procedure CCSR mapping
#' pr_map <- download_ccsr("procedure", version = "v2025.1")
#'
#' # Download without caching
#' dx_map <- download_ccsr("diagnosis", cache = FALSE)
#' }
#'
#' @importFrom httr2 request req_timeout req_user_agent req_perform resp_body_string resp_body_raw
#' @importFrom readr read_csv cols locale
#' @importFrom tibble as_tibble
#' @importFrom utils unzip
#' @importFrom xml2 read_html xml_find_all xml_attr xml_text
#' @export
download_ccsr <- function(type = "diagnosis",
                          version = "latest",
                          cache = TRUE,
                          clean_names = TRUE) {
  # Validate type
  type <- tolower(type)
  if (type %in% c("dx", "diagnosis")) {
    type <- "diagnosis"
  } else if (type %in% c("pr", "procedure")) {
    type <- "procedure"
  } else {
    stop("`type` must be one of: 'diagnosis'/'dx' or 'procedure'/'pr'")
  }

  # Get version information - do this early to ensure we have latest
  original_version <- version
  if (version == "latest") {
    # Always clear version cache when user explicitly requests "latest"
    # This ensures we get the freshest version from the website
    cache_name <- paste0("ccsr_latest_version_", type)
    cache_path <- file.path(tempdir(), cache_name)
    if (file.exists(cache_path)) {
      unlink(cache_path)  # Always clear to force fresh discovery
    }
    
    # Force refresh when requesting "latest" to ensure we get the actual latest
    version <- get_latest_version(type, force_refresh = TRUE)
    # Store the actual latest version for later comparison
    actual_latest_version <- version
  } else {
    actual_latest_version <- version
  }

  # Validate version format (accept both v2026.1 and v2026-1)
  if (!grepl("^v\\d{4}[-.]\\d+$", version)) {
    stop("`version` must be in format 'vYYYY.N' or 'vYYYY-N' (e.g., 'v2026.1' or 'v2026-1')")
  }

  # Convert version format to URL format (v2026.1 -> v2026-1)
  version_url <- gsub("\\.", "-", version)
  
  base_url <- "https://hcup-us.ahrq.gov/toolssoftware/ccsr/"
  
  # URL pattern varies by type and version:
  # - Recent diagnosis files (v2026+): DXCCSR-v2026-1.zip (hyphen)
  # - Older diagnosis files (v2025 and earlier): DXCCSR_v2025-1.zip (underscore)
  # - All procedure files: PRCCSR_v2026-1.zip (underscore)
  
  if (type == "diagnosis") {
    # Try hyphen first (newer versions), fall back to underscore (older versions)
    file_name_hyphen <- paste0("DXCCSR-", version_url, ".zip")
    file_name_underscore <- paste0("DXCCSR_", version_url, ".zip")
    
    # Check which pattern exists (try hyphen first for newer versions)
    url_hyphen <- paste0(base_url, file_name_hyphen)
    url_underscore <- paste0(base_url, file_name_underscore)
    
    # For v2026+, use hyphen; for older versions, use underscore
    year <- as.numeric(sub("v(\\d{4})[-.].*", "\\1", version))
    if (year >= 2026) {
      url <- url_hyphen
      file_name <- file_name_hyphen
    } else {
      url <- url_underscore
      file_name <- file_name_underscore
    }
  } else {
    # Procedure files always use underscore
    file_name <- paste0("PRCCSR_", version_url, ".zip")
    url <- paste0(base_url, file_name)
  }

  # Check cache if enabled
  if (cache) {
    cache_dir <- file.path(tempdir(), "HCUPtools_cache")
    if (!dir.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    cache_file <- file.path(cache_dir, file_name)
    
    # If version is "latest", check ALL cached files and find the best match
    if (original_version == "latest") {
      # Find all cached files for this type
      pattern <- if (type == "diagnosis") "DXCCSR.*\\.zip$" else "PRCCSR.*\\.zip$"
      all_cached <- list.files(cache_dir, pattern = pattern, full.names = TRUE, ignore.case = TRUE)
      
      if (length(all_cached) > 0) {
        # Extract versions from all cached files
        cached_versions <- sapply(all_cached, function(f) {
          version_match <- regmatches(basename(f), 
                                     regexpr("v\\d{4}[-.]\\d+", basename(f), 
                                            ignore.case = TRUE))
          if (length(version_match) > 0) {
            gsub("-", ".", version_match[1])
          } else {
            NA_character_
          }
        })
        
        # Find the cached file with the latest version
        valid_cached <- all_cached[!is.na(cached_versions)]
        valid_versions <- cached_versions[!is.na(cached_versions)]
        
        if (length(valid_cached) > 0) {
          # Compare with actual latest version
          actual_latest_normalized <- gsub("-", ".", actual_latest_version)
          
          # Check if any cached file matches the latest version
          matching_idx <- which(valid_versions == actual_latest_normalized)
          
          if (length(matching_idx) > 0) {
            # Found a cached file matching latest version
            cache_file <- valid_cached[matching_idx[1]]
            message("Using cached file: ", cache_file)
            zip_path <- cache_file
          } else {
            # No cached file matches latest version - download new one
            message("Cached files found (", paste(valid_versions, collapse = ", "), 
                   ") but latest is ", actual_latest_version, 
                   ". Downloading latest version...")
            # Remove old cached files (optional - could keep them)
            # unlink(valid_cached)
            zip_path <- download_file(url, cache_file)
          }
        } else {
          # Couldn't parse versions from cached files
          zip_path <- download_file(url, cache_file)
        }
      } else {
        # No cached files found
        zip_path <- download_file(url, cache_file)
      }
    } else {
      # Specific version requested - check if exact file exists
      if (file.exists(cache_file)) {
        message("Using cached file: ", cache_file)
        zip_path <- cache_file
      } else {
        zip_path <- download_file(url, cache_file)
      }
    }
  } else {
    zip_path <- download_file(url, tempfile(fileext = ".zip"))
  }

  mapping_data <- extract_and_read_ccsr(zip_path, type, version, clean_names)
  return(mapping_data)
}

#' Helper function to download file with error handling
#'
#' @noRd
download_file <- function(url, destfile) {
  message("Downloading from: ", url)
  
  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_timeout(60) |>
      httr2::req_user_agent("HCUPtools R package") |>
      httr2::req_perform()
    
    httr2::resp_body_raw(resp) |>
      writeBin(destfile)
    
    message("Download complete: ", destfile)
    return(destfile)
  }, error = function(e) {
    # Try alternative URL pattern if first attempt fails
    if (grepl("DXCCSR", url)) {
      alt_url <- gsub("DXCCSR-", "DXCCSR_", url)
      alt_url <- gsub("DXCCSR_", "DXCCSR-", alt_url)
      
      if (alt_url != url) {
        tryCatch({
          message("Trying alternative URL pattern: ", alt_url)
          resp <- httr2::request(alt_url) |>
            httr2::req_timeout(60) |>
            httr2::req_user_agent("HCUPtools R package") |>
            httr2::req_perform()
          
          httr2::resp_body_raw(resp) |>
            writeBin(destfile)
          
          message("Download complete: ", destfile)
          return(destfile)
        }, error = function(e2) {
          stop("Failed to download file from both URL patterns. ",
               "Original error: ", conditionMessage(e), ". ",
               "Alternative error: ", conditionMessage(e2))
        })
      }
    }
    stop("Failed to download file: ", conditionMessage(e))
  })
}

#' Extract and read CCSR mapping file from ZIP
#'
#' @noRd
extract_and_read_ccsr <- function(zip_path, type, version, clean_names) {
  # Create temporary extraction directory
  extract_dir <- tempfile("ccsr_extract_")
  dir.create(extract_dir, showWarnings = FALSE)
  on.exit(unlink(extract_dir, recursive = TRUE), add = TRUE)
  
  # Extract ZIP file
  utils::unzip(zip_path, exdir = extract_dir)
  
  # Find CSV or Excel file in extracted directory
  all_files <- list.files(extract_dir, recursive = TRUE, full.names = TRUE)
  
  # Look for CSV files first (preferred)
  csv_files <- all_files[grepl("\\.csv$", all_files, ignore.case = TRUE)]
  xlsx_files <- all_files[grepl("\\.xlsx?$", all_files, ignore.case = TRUE)]
  
  # Filter by type if possible
  if (type == "diagnosis") {
    csv_files <- csv_files[grepl("DX|diagnosis", basename(csv_files), ignore.case = TRUE)]
    xlsx_files <- xlsx_files[grepl("DX|diagnosis", basename(xlsx_files), ignore.case = TRUE)]
  } else {
    csv_files <- csv_files[grepl("PR|procedure", basename(csv_files), ignore.case = TRUE)]
    xlsx_files <- xlsx_files[grepl("PR|procedure", basename(xlsx_files), ignore.case = TRUE)]
  }
  
  # If no type-specific files found, use all CSV/Excel files
  if (length(csv_files) == 0 && length(xlsx_files) == 0) {
    csv_files <- all_files[grepl("\\.csv$", all_files, ignore.case = TRUE)]
    xlsx_files <- all_files[grepl("\\.xlsx?$", all_files, ignore.case = TRUE)]
  }
  
  mapping_file <- NULL
  if (length(csv_files) > 0) {
    mapping_file <- csv_files[1]
  } else if (length(xlsx_files) > 0) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is required for reading Excel files. ",
           "Install it with: install.packages('readxl')")
    }
    mapping_file <- xlsx_files[1]
  } else {
    stop("No CSV or Excel file found in the downloaded ZIP archive")
  }
  
  if (length(mapping_file) > 1) {
    warning("Multiple mapping files found, using: ", mapping_file[1])
    mapping_file <- mapping_file[1]
  }

  message("Reading mapping file: ", basename(mapping_file))
  
  mapping_data <- readr::read_csv(
    mapping_file,
    col_types = readr::cols(.default = "c"),
    locale = readr::locale(encoding = "UTF-8"),
    show_col_types = FALSE
  )

  mapping_data <- tibble::as_tibble(mapping_data)

  if (clean_names) {
    names(mapping_data) <- clean_column_names(names(mapping_data))
  }

  icd_col <- find_icd_column(mapping_data, type)
  if (!is.null(icd_col)) {
    mapping_data[[icd_col]] <- format_icd_codes(mapping_data[[icd_col]])
  }

  return(mapping_data)
}

#' Helper function to clean column names
#'
#' @noRd
clean_column_names <- function(names) {
  names <- gsub("\\s+", "_", names)
  names <- gsub("[^A-Za-z0-9_]", "", names)
  names <- tolower(names)
  names <- gsub("_+", "_", names)
  names <- gsub("^_|_$", "", names)
  return(names)
}

#' Helper function to find ICD code column
#'
#' @noRd
find_icd_column <- function(df, type) {
  col_names <- tolower(names(df))
  
  if (type == "diagnosis") {
    patterns <- c("icd.*10.*cm", "icd.*10", "diagnosis.*code", "^code$", "^dx$")
  } else {
    patterns <- c("icd.*10.*pcs", "icd.*10", "procedure.*code", "^code$", "^pr$")
  }
  
  for (pattern in patterns) {
    match <- grep(pattern, col_names, value = TRUE)
    if (length(match) > 0) {
      return(match[1])
    }
  }
  
  return(names(df)[1])
}

#' Get latest available CCSR version from HCUP website
#'
#' Fetches the latest available CCSR version from the HCUP website
#' for the specified type (diagnosis or procedure). Results are cached for
#' 6 hours to minimize website requests.
#'
#' @param type Character string, either "diagnosis" or "procedure"
#' @return Character string with version (e.g., "v2026.1")
#'
#' @noRd
get_latest_version <- function(type, force_refresh = FALSE) {
  # Cache the result to avoid repeated requests
  cache_name <- paste0("ccsr_latest_version_", type)
  cache_path <- file.path(tempdir(), cache_name)
  
  # If force_refresh is TRUE, clear cache and fetch fresh
  if (force_refresh && file.exists(cache_path)) {
    unlink(cache_path)
  }
  
  # Check cache (valid for 6 hours)
  if (!force_refresh && file.exists(cache_path)) {
    cache_info <- file.info(cache_path)
    cache_age <- as.numeric(Sys.time() - cache_info$mtime, units = "hours")
    if (cache_age < 6) {
      cached_version <- readLines(cache_path, n = 1, warn = FALSE)
      if (nchar(cached_version) > 0 && grepl("^v\\d{4}[-.]\\d+$", cached_version)) {
        # Verify cached version is not too old (should be within last 2 years)
        year_match <- regmatches(cached_version, regexec("v(\\d{4})", cached_version))[[1]]
        if (length(year_match) >= 2) {
          cached_year <- as.numeric(year_match[2])
          current_year <- as.numeric(format(Sys.Date(), "%Y"))
          # Accept cached version if it's from current year or next year
          if (cached_year >= current_year) {
            return(cached_version)
          }
        }
      }
    }
  }
  
  file_prefix <- if (type == "diagnosis") "DXCCSR" else "PRCCSR"
  
  latest_version <- tryCatch({
    fetch_hcup_versions(file_prefix)
  }, error = function(e) {
    warning("Could not fetch latest version from HCUP website: ", 
            conditionMessage(e), 
            ". Using fallback version based on current year")
    NULL
  })
  
  # Validate the version format
  if (is.null(latest_version) || !grepl("^v\\d{4}[-.]\\d+$", latest_version)) {
    # If we can't fetch, try direct file checking as last resort
    latest_version <- try_fetch_versions_direct(file_prefix)
    if (is.null(latest_version) || length(latest_version) == 0) {
      # Last resort: use current year + 1 as fallback (to catch early releases)
      current_year <- as.numeric(format(Sys.Date(), "%Y"))
      # Check if next year version exists, otherwise use current year
      test_year <- current_year + 1
      test_file <- if (file_prefix == "DXCCSR" && test_year >= 2026) {
        paste0(file_prefix, "-v", test_year, "-1.zip")
      } else {
        paste0(file_prefix, "_v", test_year, "-1.zip")
      }
      test_url <- paste0("https://hcup-us.ahrq.gov/toolssoftware/ccsr/", test_file)
      
      next_year_exists <- tryCatch({
        resp <- httr2::request(test_url) |>
          httr2::req_method("HEAD") |>
          httr2::req_user_agent("HCUPtools R package") |>
          httr2::req_timeout(3) |>
          httr2::req_perform()
        httr2::resp_status(resp) %in% c(200, 302, 301)
      }, error = function(e) FALSE)
      
      if (next_year_exists) {
        latest_version <- paste0("v", test_year, ".1")
      } else {
        latest_version <- paste0("v", current_year, ".1")
      }
      warning("Could not determine latest version from HCUP website. ",
              "Using fallback version: ", latest_version,
              ". This may not be the actual latest version.")
    } else {
      latest_version <- get_latest_from_versions(latest_version)
    }
  }
  
  writeLines(latest_version, cache_path)
  return(latest_version)
}

#' Fetch available CCSR versions from HCUP website
#'
#' @param file_prefix Character string, either "DXCCSR" or "PRCCSR"
#' @return Character string with latest version, or NULL if not found
#'
#' @noRd
fetch_hcup_versions <- function(file_prefix) {
  # Try direct file checking FIRST (most reliable)
  # This directly checks if files exist, which is more accurate than parsing HTML
  versions_direct <- try_fetch_versions_direct(file_prefix)
  if (!is.null(versions_direct) && length(versions_direct) > 0) {
    # Direct file check found versions - use these (most reliable)
    return(get_latest_from_versions(versions_direct))
  }
  
  # Fallback: Try multiple URLs to find versions
  urls_to_try <- c(
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp",
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/",
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp"
  )
  
  all_versions <- character(0)
  
  for (url in urls_to_try) {
    versions <- try_fetch_versions_from_url(url, file_prefix)
    if (!is.null(versions) && length(versions) > 0) {
      all_versions <- c(all_versions, versions)
    }
  }
  
  if (length(all_versions) > 0) {
    # Remove duplicates and get latest
    all_versions <- unique(all_versions)
    return(get_latest_from_versions(all_versions))
  }
  
  NULL
}

#' Fetch versions from a specific URL
#'
#' @param url Character string, URL to fetch
#' @param file_prefix Character string, either "DXCCSR" or "PRCCSR"
#' @return Character vector of version strings, or NULL if error
#'
#' @noRd
try_fetch_versions_from_url <- function(url, file_prefix) {
  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_user_agent("HCUPtools R package") |>
      httr2::req_timeout(10) |>
      httr2::req_perform()
    
    html_content <- httr2::resp_body_string(resp)
    doc <- xml2::read_html(html_content)
    
    links <- xml2::xml_find_all(doc, "//a[@href]")
    hrefs <- xml2::xml_attr(links, "href")
    
    text_nodes <- xml2::xml_find_all(doc, "//text()[normalize-space()]")
    text_content <- xml2::xml_text(text_nodes)
    all_text <- paste(text_content, collapse = " ")
    
    all_content <- c(hrefs, all_text)
    
    # Pattern to match both v2026.1 and v2026-1 formats
    version_pattern <- paste0(file_prefix, ".*?(v\\d{4}[-.]\\d+)")
    version_matches <- regmatches(all_content, 
                                 gregexpr(version_pattern, all_content, 
                                         ignore.case = TRUE))
    versions <- unlist(version_matches)
    
    if (length(versions) > 0) {
      versions <- gsub(paste0(".*(v\\d{4}[-.]\\d+).*"), "\\1", versions, 
                      ignore.case = TRUE)
      versions <- unique(versions)
      # Normalize to dot format for internal use (v2026-1 -> v2026.1)
      versions <- gsub("-", ".", versions)
      versions <- grep("^v\\d{4}\\.\\d+$", versions, value = TRUE, ignore.case = TRUE)
      return(versions)
    }
    
    NULL
  }, error = function(e) {
    NULL
  })
}

#' Get the latest version from a vector of version strings
#'
#' @param versions Character vector of version strings (e.g., c("v2026.1", "v2025.1"))
#' @return Character string with the latest version
#'
#' @noRd
get_latest_from_versions <- function(versions) {
  if (length(versions) == 0) {
    return(NULL)
  }
  
  # Normalize all versions to vYYYY.N format
  normalized <- vapply(versions, function(v) {
    # Handle both v2026.1 and v2026-1 formats
    v_clean <- gsub("-", ".", v)
    parts <- regmatches(v_clean, regexec("v(\\d{4})\\.(\\d+)", v_clean, ignore.case = TRUE))[[1]]
    if (length(parts) >= 3) {
      year <- as.numeric(parts[2])
      minor <- as.numeric(parts[3])
      # Create sortable numeric value: year * 1000 + minor
      # This ensures v2026.1 > v2025.10
      sort_value <- year * 1000 + minor
      return(sort_value)
    } else {
      return(NA_real_)
    }
  }, numeric(1))
  
  valid_idx <- !is.na(normalized)
  if (any(valid_idx)) {
    # Find the maximum sort value
    max_idx <- which.max(normalized[valid_idx])
    latest_version <- versions[valid_idx][max_idx]
    # Normalize to dot format
    latest_version <- gsub("-", ".", latest_version)
    return(latest_version)
  }
  
  # Fallback: return first version
  return(gsub("-", ".", versions[1]))
}

#' Try to fetch versions by attempting direct file access
#'
#' @param file_prefix Character string, either "DXCCSR" or "PRCCSR"
#' @return Character vector of version strings, or NULL if error
#'
#' @noRd
try_fetch_versions_direct <- function(file_prefix) {
  # Try to find versions by checking common patterns
  # Check next year, current year, and previous year (to catch early releases)
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  versions_found <- character(0)
  
  # Determine correct separator based on file type and year
  # DXCCSR v2026+ uses hyphen, DXCCSR v2025 and earlier uses underscore
  # PRCCSR always uses underscore
  use_hyphen_for_year <- function(year) {
    file_prefix == "DXCCSR" && year >= 2026
  }
  
  # Check years in order: next year (2026), current year (2025), previous year (2024)
  # This catches early releases of next year's version
  years_to_check <- c(current_year + 1, current_year, current_year - 1)
  
  for (year in years_to_check) {
    # Check minor versions (usually 1-2, but check up to 3)
    for (minor in 1:3) {
      # Determine separator BEFORE version (not between year and minor)
      # Year and minor are always separated by hyphen: v2026-1
      # But the separator before "v" depends on file type and year
      prefix_sep <- if (use_hyphen_for_year(year)) "-" else "_"
      version_str <- paste0("v", year, "-", minor)  # Always hyphen between year and minor
      file_name <- paste0(file_prefix, prefix_sep, version_str, ".zip")
      url <- paste0("https://hcup-us.ahrq.gov/toolssoftware/ccsr/", file_name)
      
      # Quick HEAD request to check if file exists
      file_exists <- tryCatch({
        resp <- httr2::request(url) |>
          httr2::req_method("HEAD") |>
          httr2::req_user_agent("HCUPtools R package") |>
          httr2::req_timeout(5) |>
          httr2::req_perform()
        
        status <- httr2::resp_status(resp)
        status %in% c(200, 302, 301, 303)
      }, error = function(e) FALSE)
      
      if (file_exists) {
        versions_found <- c(versions_found, paste0("v", year, ".", minor))
        # If we found next year version, return immediately (it's the latest)
        if (year > current_year) {
          return(versions_found)  # Next year found - this is definitely the latest
        }
        # For current year or previous year, continue checking all minor versions
      }
      
      # If hyphen didn't work for DXCCSR v2026+, try underscore as fallback (only for first minor)
      if (!file_exists && use_hyphen_for_year(year) && minor == 1) {
        prefix_sep <- "_"
        version_str <- paste0("v", year, "-", minor)  # Always hyphen between year and minor
        file_name <- paste0(file_prefix, prefix_sep, version_str, ".zip")
        url <- paste0("https://hcup-us.ahrq.gov/toolssoftware/ccsr/", file_name)
        
        file_exists <- tryCatch({
          resp <- httr2::request(url) |>
            httr2::req_method("HEAD") |>
            httr2::req_user_agent("HCUPtools R package") |>
            httr2::req_timeout(5) |>
            httr2::req_perform()
          
          status <- httr2::resp_status(resp)
          status %in% c(200, 302, 301, 303)
        }, error = function(e) FALSE)
        
        if (file_exists) {
          versions_found <- c(versions_found, paste0("v", year, ".", minor))
          # If we found next year version, return immediately
          if (year > current_year) {
            return(versions_found)
          }
        }
      }
    }
    
    # After checking all minor versions for next year, if we found any, return them
    if (year > current_year && length(versions_found) > 0) {
      return(versions_found)
    }
  }
  
  if (length(versions_found) > 0) {
    return(unique(versions_found))
  }
  
  NULL
}

#' Helper function to format ICD codes (preserve leading zeros)
#'
#' @noRd
format_icd_codes <- function(codes) {
  # Remove quotes and whitespace, preserve leading zeros
  codes <- gsub("^['\"]|['\"]$", "", codes)
  codes <- trimws(codes)
  return(codes)
}
