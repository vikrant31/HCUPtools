# Test file for ccsr_map function

test_that("ccsr_map validates inputs", {
  # Create sample data
  sample_data <- tibble::tibble(
    id = 1:3,
    code = c("E11.9", "I10", "M79.3")
  )
  
  # Create sample mapping data
  sample_map <- tibble::tibble(
    icd_code = c("E11.9", "I10", "M79.3"),
    ccsr_category = c("END001", "CIR019", "MUS003")
  )
  
  # Test invalid data
  expect_error(ccsr_map(data = "not a dataframe", code_col = "code", map_df = sample_map),
               "must be a data frame")
  
  # Test invalid code column
  expect_error(ccsr_map(data = sample_data, code_col = "nonexistent", map_df = sample_map),
               "not found in")
  
  # Test invalid output format
  expect_error(ccsr_map(data = sample_data, code_col = "code", map_df = sample_map,
                        output_format = "invalid"),
               "must be one of")
})

test_that("ccsr_map handles output formats", {
  sample_data <- tibble::tibble(
    id = 1:2,
    code = c("A000", "B111")
  )

  sample_map <- tibble::tibble(
    icd_10_cm_code = c("'A000'", "B111"),
    ccsr_category_1 = c("'DIG001'", "RSP002"),
    ccsr_category_2 = c("'INF003'", NA_character_),
    ccsr_category_3 = c(NA_character_, NA_character_),
    ccsr_category_4 = c(NA_character_, NA_character_),
    ccsr_category_5 = c(NA_character_, NA_character_),
    ccsr_category_6 = c(NA_character_, NA_character_),
    default_ccsr_category = c("'DIG001'", "RSP002")
  )

  mapped_long <- ccsr_map(
    data = sample_data,
    code_col = "code",
    map_df = sample_map,
    output_format = "long",
    default_only = FALSE
  )

  a000_rows <- mapped_long[mapped_long$code == "A000", ]
  expect_equal(sort(a000_rows$ccsr_category), c("DIG001", "INF003"))
  expect_true(any(a000_rows$is_default))
  expect_equal(sum(a000_rows$is_default), 1)

  mapped_default <- ccsr_map(
    data = sample_data,
    code_col = "code",
    map_df = sample_map,
    output_format = "long",
    default_only = TRUE
  )

  expect_equal(mapped_default$ccsr_category[mapped_default$code == "A000"], "DIG001")
  expect_true(all(mapped_default$is_default %in% c(TRUE, NA)))

  mapped_wide <- ccsr_map(
    data = sample_data,
    code_col = "code",
    map_df = sample_map,
    output_format = "wide",
    default_only = FALSE
  )

  expect_true(all(c("CCSR_1", "CCSR_2") %in% names(mapped_wide)))
  expect_equal(mapped_wide$CCSR_1[mapped_wide$code == "A000"], "DIG001")
  expect_equal(mapped_wide$CCSR_2[mapped_wide$code == "A000"], "INF003")
})

