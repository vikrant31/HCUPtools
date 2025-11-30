#' List Available CCSR Versions
#'
#' Returns a list of available CCSR versions for download by scraping the HCUP
#' website. This function helps users identify which versions are available for
#' diagnosis and procedure mapping files.
#'
#' @param type Character string specifying the type of CCSR file. Must be one
#'   of: "diagnosis" (or "dx"), "procedure" (or "pr"), or "all" (default) to
#'   list versions for both types.
#'
#' @return A data frame (tibble) with columns:
#'   - `type`: The CCSR type ("diagnosis" or "procedure")
#'   - `version`: The version identifier (e.g., "v2026.1")
#'
#' @details
#' This function fetches available CCSR versions from the HCUP website.
#' Results are cached for 24 hours to minimize website requests. If the website
#' cannot be accessed, the function will return an error.
#'
#' @examples
#' \dontrun{
#' # List all available versions
#' list_ccsr_versions()
#'
#' # List only diagnosis versions
#' list_ccsr_versions("diagnosis")
#'
#' # List only procedure versions
#' list_ccsr_versions("procedure")
#' }
#'
#' @importFrom dplyr bind_rows mutate arrange select desc
#' @importFrom rlang .data
#' @importFrom tibble tibble
#' @export
list_ccsr_versions <- function(type = "all") {
  # Validate type
  type <- tolower(type)
  if (type %in% c("dx", "diagnosis")) {
    type <- "diagnosis"
  } else if (type %in% c("pr", "procedure")) {
    type <- "procedure"
  } else if (type != "all") {
    stop("`type` must be one of: 'all', 'diagnosis'/'dx', or 'procedure'/'pr'")
  }
  
  # Cache key for storing results
  cache_name <- "ccsr_all_versions"
  cache_path <- file.path(tempdir(), cache_name)
  
  # Check cache (valid for 24 hours)
  all_versions <- NULL
  if (file.exists(cache_path)) {
    cache_info <- file.info(cache_path)
    cache_age <- as.numeric(Sys.time() - cache_info$mtime, units = "hours")
    if (cache_age < 24) {
      tryCatch({
        cached_data <- readRDS(cache_path)
        if (inherits(cached_data, "data.frame") && 
            "type" %in% names(cached_data) && 
            "version" %in% names(cached_data)) {
          all_versions <- cached_data
        }
      }, error = function(e) {
        # Cache file corrupted, will re-fetch
      })
    }
  }
  
  # If not cached, fetch from HCUP website
  if (is.null(all_versions)) {
    dx_versions <- try_fetch_all_versions_from_url("DXCCSR")
    pr_versions <- try_fetch_all_versions_from_url("PRCCSR")
    
    # Combine results
    result_list <- list()
    if (!is.null(dx_versions) && length(dx_versions) > 0) {
      result_list <- c(result_list, list(
        tibble::tibble(type = "diagnosis", version = dx_versions)
      ))
    }
    if (!is.null(pr_versions) && length(pr_versions) > 0) {
      result_list <- c(result_list, list(
        tibble::tibble(type = "procedure", version = pr_versions)
      ))
    }
    
    if (length(result_list) > 0) {
      all_versions <- dplyr::bind_rows(result_list)
      # Sort by version (newest first)
      all_versions <- all_versions |>
        dplyr::mutate(
          version_num = as.numeric(gsub("v(\\d{4})[-.](\\d+)", "\\1.\\2", .data$version))
        ) |>
        dplyr::arrange(dplyr::desc(.data$version_num)) |>
        dplyr::select(-.data$version_num)
      
      # Cache the result
      tryCatch({
        saveRDS(all_versions, cache_path)
      }, error = function(e) {
        # Cache save failed, continue without caching
      })
    } else {
      stop("Could not retrieve CCSR versions from HCUP website. ",
           "Please check your internet connection and try again.")
    }
  }
  
  # Filter by type if specified
  if (type == "diagnosis") {
    return(all_versions[all_versions$type == "diagnosis", ])
  } else if (type == "procedure") {
    return(all_versions[all_versions$type == "procedure", ])
  } else {
    return(all_versions)
  }
}

#' Fetch all versions from HCUP website for a specific file prefix
#'
#' @param file_prefix Character string, either "DXCCSR" or "PRCCSR"
#' @return Character vector of version strings, or NULL if error
#'
#' @noRd
try_fetch_all_versions_from_url <- function(file_prefix) {
  # Try main page first
  versions <- try_fetch_versions_from_url(
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/", 
    file_prefix
  )
  if (!is.null(versions) && length(versions) > 0) {
    return(versions)
  }
  
  # Try archive page
  versions <- try_fetch_versions_from_url(
    "https://hcup-us.ahrq.gov/toolssoftware/ccsr/ccsr_archive.jsp", 
    file_prefix
  )
  if (!is.null(versions) && length(versions) > 0) {
    return(versions)
  }
  
  return(NULL)
}
