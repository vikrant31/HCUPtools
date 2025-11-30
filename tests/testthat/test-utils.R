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

