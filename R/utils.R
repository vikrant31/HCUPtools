#' Format ICD codes (preserve leading zeros)
#'
#' @param codes Character or numeric vector of ICD codes
#' @return Character vector of formatted ICD codes
#'
#' @noRd
format_icd_codes <- function(codes) {
  return(trimws(as.character(codes)))
}

