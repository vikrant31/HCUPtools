# Test file for download_ccsr function
# Note: These tests may require internet connection and may be skipped in CI/CD

test_that("download_ccsr validates type argument", {
  expect_error(download_ccsr(type = "invalid"), 
               "must be one of")
  # Note: Actual download test skipped to avoid internet dependency in CRAN checks
  skip_on_cran()
})

test_that("download_ccsr validates version argument", {
  expect_error(download_ccsr(type = "diagnosis", version = "invalid"),
               "must be in format")
})

test_that("list_ccsr_versions returns expected structure", {
  skip_on_cran()  # Requires internet access
  skip_if_offline()  # Skip if no internet
  
  versions <- list_ccsr_versions()
  expect_s3_class(versions, "tbl_df")
  expect_true("type" %in% names(versions))
  expect_true("version" %in% names(versions))
})

test_that("list_ccsr_versions filters by type", {
  skip_on_cran()  # Requires internet access
  skip_if_offline()  # Skip if no internet
  
  dx_versions <- list_ccsr_versions("diagnosis")
  expect_true(all(dx_versions$type == "diagnosis"))
  
  pr_versions <- list_ccsr_versions("procedure")
  expect_true(all(pr_versions$type == "procedure"))
})

