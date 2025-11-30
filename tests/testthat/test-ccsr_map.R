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
  # This would require actual mapping data, so it's a placeholder
  # In practice, you'd download real data or use mock data
  skip("Requires actual CCSR mapping data")
})

