# Test file for utility functions

test_that("format_icd_codes preserves leading zeros", {
  codes <- c("E08.00", "001.0", "123")
  formatted <- format_icd_codes(codes)
  expect_type(formatted, "character")
  expect_equal(formatted[1], "E08.00")
})

test_that("format_icd_codes handles whitespace", {
  codes <- c("  E11.9  ", "I10", " M79.3 ")
  formatted <- format_icd_codes(codes)
  expect_equal(formatted[1], "E11.9")
  expect_equal(formatted[3], "M79.3")
})

test_that("format_icd_codes strips surrounding quotes", {
  codes <- c("'A000'", "\"B111\"")
  formatted <- format_icd_codes(codes)
  expect_equal(formatted, c("A000", "B111"))
})

test_that("get_ccsr_description matches quoted mapping codes", {
  map_df <- tibble::tibble(
    ccsr_category = c("'DIG001'", "'RSP002'"),
    ccsr_category_description = c("Digestive disorders", "Respiratory disorders")
  )

  result <- get_ccsr_description(c("DIG001", "RSP002"), map_df = map_df, type = "diagnosis")
  expect_equal(result$description, c("Digestive disorders", "Respiratory disorders"))
})

test_that("hcup_citation returns correct format", {
  text_cite <- hcup_citation(format = "text")
  expect_type(text_cite, "character")
  expect_true(nchar(text_cite) > 0)
  
  bibtex_cite <- hcup_citation(format = "bibtex")
  expect_type(bibtex_cite, "character")
  expect_true(grepl("@misc", bibtex_cite))
  
  r_cite <- hcup_citation(format = "r")
  expect_type(r_cite, "list")
})

