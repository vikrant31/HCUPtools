#!/usr/bin/env Rscript
# Exercise every exported function in HCUPtools (see NAMESPACE).
#
# Usage (from anywhere):
#   Rscript scripts/verify_all_exports.R
# Or from R: source("/full/path/to/HCUPtools/scripts/verify_all_exports.R")
#   (getwd() may be anywhere; the script resolves the package from the path.)
#
# Requires: network access to HCUP, and suggested packages from DESCRIPTION
#   (testthat/devtools only if you use --load=devtools below).
#
# This is a smoke/integration script, not a replacement for testthat.

options(warn = 1)

has_description <- function(dir) {
  nzchar(dir) && file.exists(file.path(dir, "DESCRIPTION"))
}

find_pkg_root <- function() {
  env <- Sys.getenv("HCUPTOOLS_ROOT", "")
  if (nzchar(env) && has_description(env)) {
    return(normalizePath(env, winslash = "/", mustWork = FALSE))
  }

  # Rscript: --file=/path/to/scripts/verify_all_exports.R
  args <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(f) && nzchar(f[1])) {
    script_dir <- tryCatch(
      dirname(normalizePath(f[1], winslash = "/", mustWork = TRUE)),
      error = function(e) character()
    )
    if (nzchar(script_dir)) {
      cand <- dirname(script_dir)
      if (has_description(cand)) {
        return(normalizePath(cand, winslash = "/", mustWork = FALSE))
      }
    }
  }

  # source("/path/.../scripts/verify_all_exports.R"): path appears on the stack
  calls <- sys.calls()
  for (k in rev(seq_along(calls))) {
    cl <- calls[[k]]
    if (is.call(cl) && identical(cl[[1L]], as.name("source"))) {
      p <- cl[[2L]]
      if (is.character(p) && length(p) == 1L && nzchar(p)) {
        script_dir <- tryCatch(
          dirname(normalizePath(p, winslash = "/", mustWork = TRUE)),
          error = function(e) character()
        )
        if (nzchar(script_dir)) {
          cand <- dirname(script_dir)
          if (has_description(cand)) {
            return(normalizePath(cand, winslash = "/", mustWork = FALSE))
          }
        }
      }
    }
  }

  # source(...): ofile on a frame (works in some R versions / contexts)
  ofile <- NULL
  for (i in seq_len(sys.nframe())) {
    o <- sys.frame(i)$ofile
    if (!is.null(o) && nzchar(o)) {
      ofile <- o
      break
    }
  }
  if (!is.null(ofile) && nzchar(ofile)) {
    script_dir <- tryCatch(
      dirname(normalizePath(ofile, winslash = "/", mustWork = TRUE)),
      error = function(e) character()
    )
    if (nzchar(script_dir)) {
      cand <- dirname(script_dir)
      if (has_description(cand)) {
        return(normalizePath(cand, winslash = "/", mustWork = FALSE))
      }
    }
  }

  # Walk up from working directory
  d <- tryCatch(normalizePath(getwd(), winslash = "/", mustWork = TRUE), error = function(e) getwd())
  for (k in seq_len(20L)) {
    if (has_description(d)) {
      return(normalizePath(d, winslash = "/", mustWork = FALSE))
    }
    parent <- dirname(d)
    if (identical(parent, d)) {
      break
    }
    d <- parent
  }

  NA_character_
}

pkg_root <- find_pkg_root()
if (is.na(pkg_root) || !nzchar(pkg_root)) {
  stop(
    "Could not find package root (a directory containing DESCRIPTION).\n",
    "Fix: set Sys.setenv(HCUPTOOLS_ROOT = \"/path/to/HCUPtools\") before sourcing,\n",
    "or setwd() to the package root, or run: Rscript scripts/verify_all_exports.R"
  )
}

load_mode <- Sys.getenv("HCUPTOOLS_LOAD", "devtools") # "devtools" | "installed"

if (identical(load_mode, "devtools")) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools", repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(
    devtools::load_all(pkg_root, reset = TRUE, recompile = FALSE)
  )
} else {
  if (!requireNamespace("HCUPtools", quietly = TRUE)) {
    stop("Install HCUPtools first or use HCUPTOOLS_LOAD=devtools")
  }
  library(HCUPtools)
}

exports <- sort(getNamespaceExports("HCUPtools"))
cat("Exported objects (NAMESPACE): ", length(exports), "\n", sep = "")
cat(paste(exports, collapse = ", "), "\n\n")

results <- data.frame(
  test = character(),
  status = character(),
  message = character(),
  stringsAsFactors = FALSE
)

log_result <- function(test, status, msg = "") {
  results <<- rbind(results, data.frame(
    test = test,
    status = status,
    message = msg,
    stringsAsFactors = FALSE
  ))
  cat(sprintf("[%s] %s %s\n", status, test, if (nzchar(msg)) paste0("- ", msg) else ""))
}

run <- function(test, expr) {
  q <- substitute(expr)
  tryCatch(
    {
      eval(q, envir = parent.frame())
      log_result(test, "PASS")
    },
    error = function(e) {
      log_result(test, "FAIL", conditionMessage(e))
    }
  )
}

ccsr_version <- "v2025.1" # stable for downloads; change if HCUP drops this release

# --- 1. hcup_citation (no HCUP download) ------------------------------------
run("hcup_citation() default", {
  x <- hcup_citation()
  stopifnot(is.character(x), nzchar(x))
})
run("hcup_citation bibtex + fixed version", {
  x <- hcup_citation(format = "bibtex", version = ccsr_version)
  stopifnot(is.character(x), nzchar(x))
})
run("hcup_citation r object", {
  x <- hcup_citation(format = "r", version = ccsr_version)
  stopifnot(inherits(x, "bibentry"))
})
run("hcup_citation trend_tables", {
  x <- hcup_citation(resource = "trend_tables", format = "text")
  stopifnot(is.character(x), nzchar(x))
})

# --- 2–3. Network: CCSR index + download ------------------------------------
dx_map <- NULL
pr_map <- NULL
trend_xlsx <- NULL

run("list_ccsr_versions()", {
  v <- list_ccsr_versions()
  stopifnot(is.data.frame(v) || is.vector(v))
})

run("list_ccsr_versions(\"diagnosis\")", {
  v <- list_ccsr_versions("diagnosis")
  stopifnot(is.data.frame(v) || is.vector(v))
})

run("download_ccsr diagnosis", {
  dx_map <<- download_ccsr("diagnosis", version = ccsr_version)
  stopifnot(is.data.frame(dx_map) || inherits(dx_map, "tbl_df"))
  stopifnot(nrow(dx_map) > 0L)
})

run("download_ccsr procedure", {
  pr_map <<- download_ccsr("procedure", version = ccsr_version)
  stopifnot(is.data.frame(pr_map) || inherits(pr_map, "tbl_df"))
  stopifnot(nrow(pr_map) > 0L)
})

# --- 4–6. Mapping + descriptions ---------------------------------------------
run("get_ccsr_description with map_df", {
  d <- get_ccsr_description(c("END002", "END005"), map_df = dx_map)
  stopifnot(is.data.frame(d) || inherits(d, "tbl_df"))
})

run("ccsr_map long", {
  samp <- tibble::tibble(id = 1:2, icd = c("E11.9", "I10"))
  m <- ccsr_map(samp, code_col = "icd", map_df = dx_map, output_format = "long")
  stopifnot(nrow(m) >= 2L)
})

run("ccsr_map wide + default_only", {
  samp <- tibble::tibble(id = 1:2, icd = c("E11.9", "I10"))
  w <- ccsr_map(samp, code_col = "icd", map_df = dx_map, output_format = "wide")
  d0 <- ccsr_map(samp, code_col = "icd", map_df = dx_map, default_only = TRUE)
  stopifnot(nrow(w) >= 1L, nrow(d0) >= 1L)
})

run("ccsr_map procedure long", {
  icd_col <- grep("icd", names(pr_map), ignore.case = TRUE, value = TRUE)[1]
  stopifnot(!is.na(icd_col), nzchar(icd_col))
  n <- min(3L, nrow(pr_map))
  samp <- data.frame(id = seq_len(n), code = pr_map[[icd_col]][seq_len(n)])
  m <- ccsr_map(samp, code_col = "code", map_df = pr_map, output_format = "long")
  stopifnot(nrow(m) >= 1L)
})

# --- 7–10. Trend tables -------------------------------------------------------
if (!interactive()) {
  run("download_trend_tables() listing", {
    tab <- download_trend_tables()
    stopifnot(is.data.frame(tab) || inherits(tab, "tbl_df"))
    stopifnot(nrow(tab) > 0L)
  })
} else {
  log_result(
    "download_trend_tables() listing",
    "SKIP",
    "with table_id = NULL, interactive() opens a menu and may return a file path, not a table"
  )
}

run("download_trend_tables(\"2a\")", {
  trend_xlsx <<- download_trend_tables("2a")
  stopifnot(is.character(trend_xlsx), length(trend_xlsx) == 1L, file.exists(trend_xlsx))
})

run("list_trend_table_sheets", {
  sh <- list_trend_table_sheets(trend_xlsx)
  stopifnot(is.character(sh), length(sh) > 0L)
})

run("read_trend_table from file", {
  d <- read_trend_table(
    file_path = trend_xlsx,
    as_data_table = FALSE
  )
  stopifnot(is.data.frame(d) || inherits(d, "tbl_df"))
  stopifnot(nrow(d) > 0L)
})

# --- 11. read_ccsr from cache ------------------------------------------------
run("read_ccsr diagnosis from cache", {
  r <- read_ccsr(type = "diagnosis", version = ccsr_version, as_data_table = FALSE)
  stopifnot(is.data.frame(r) || inherits(r, "tbl_df"))
  stopifnot(nrow(r) > 0L)
})

run("read_ccsr procedure from cache", {
  r <- read_ccsr(type = "procedure", version = ccsr_version, as_data_table = FALSE)
  stopifnot(is.data.frame(r) || inherits(r, "tbl_df"))
  stopifnot(nrow(r) > 0L)
})

# --- 12. ccsr_changelog (several formats) ------------------------------------
run("ccsr_changelog url", {
  u <- ccsr_changelog(version = ccsr_version, format = "url")
  stopifnot(is.character(u), nzchar(u[1]))
})

run("ccsr_changelog text", {
  t <- ccsr_changelog(version = ccsr_version, format = "text")
  stopifnot(is.character(t), nzchar(paste(t, collapse = "")))
})

run("ccsr_changelog download", {
  p <- ccsr_changelog(version = ccsr_version, format = "download")
  stopifnot(is.character(p), file.exists(p[1]))
})

run("ccsr_changelog read", {
  tb <- ccsr_changelog(version = ccsr_version, format = "read", as_data_table = FALSE)
  stopifnot(is.data.frame(tb) || inherits(tb, "tbl_df"))
})

if (interactive()) {
  run("ccsr_changelog view (interactive only)", {
    invisible(ccsr_changelog(version = ccsr_version, format = "view"))
  })
} else {
  log_result("ccsr_changelog view (interactive only)", "SKIP", "non-interactive session")
}

run("ccsr_changelog extract", {
  tx <- ccsr_changelog(version = ccsr_version, format = "extract")
  stopifnot(is.character(tx))
})

# Each NAMESPACE export is invoked at least once above (changelog "view" only
# when interactive(); `format = "extract"` needs readxl for Excel logs and
# pdftools when HCUP serves a PDF).

cat("\n=== Summary ===\n")
print(table(results$status, useNA = "ifany"))

n_fail <- sum(results$status == "FAIL")
if (n_fail > 0L) {
  cat("\nFailures:\n")
  print(results[results$status == "FAIL", ])
  quit(status = 1L)
}
cat("\nAll export smoke tests completed without failure.\n")
quit(status = 0L)
