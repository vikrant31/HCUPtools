# Reproducible Examples for HCUPtools Manuscript
# This script demonstrates the code examples presented in the SoftwareX manuscript

# Load required packages
library(HCUPtools)
library(dplyr)

# Create sample patient data for demonstration
patient_data <- tibble::tibble(
  patient_id = 1:10,
  icd10_code = c("E11.9", "I10", "M79.3", "E78.5", "K21.9", 
                 "I50.9", "N18.6", "E78.5", "I25.10", "J44.1")
)

# ============================================================================
# Example 1: Cross-Classification Analysis (Section 3.1)
# ============================================================================

# Download CCSR diagnosis mapping file
dx_map <- download_ccsr("diagnosis")

# Map ICD-10 codes to CCSR categories using long format
mapped_data <- ccsr_map(
  data = patient_data,
  code_col = "icd10_code",
  map_df = dx_map,
  output_format = "long"
)

# Count occurrences of each CCSR category
ccsr_frequency <- mapped_data |>
  count(default_ccsr_category_ip, sort = TRUE)

print(ccsr_frequency)

# ============================================================================
# Example 2: Patient-Level Analysis (Section 3.2)
# ============================================================================

# Map codes using wide format for patient-level analysis
mapped_wide <- ccsr_map(
  data = patient_data,
  code_col = "icd10_code",
  map_df = dx_map,
  output_format = "wide"
)

# Summarize categories per patient
patient_summary <- mapped_wide |>
  rowwise() |>
  mutate(
    total_categories = sum(!is.na(c_across(starts_with("CCSR"))))
  ) |>
  ungroup() |>
  group_by(patient_id) |>
  summarize(
    total_categories = sum(total_categories > 0),
    primary_category = first(CCSR_1)
  )

print(patient_summary)

# ============================================================================
# Example 3: Principal Diagnosis Analysis (Section 3.3)
# ============================================================================

# Map codes to default category only
mapped_default <- ccsr_map(
  data = patient_data,
  code_col = "icd10_code",
  map_df = dx_map,
  default_only = TRUE
)

# Get unique CCSR categories and their descriptions
unique_ccsr <- unique(mapped_default$default_ccsr_category_ip)
unique_ccsr <- unique_ccsr[!is.na(unique_ccsr)]

if (length(unique_ccsr) > 0) {
  ccsr_descriptions <- get_ccsr_description(unique_ccsr, map_df = dx_map)
  
  # Join with descriptions for analysis
  principal_dx_analysis <- mapped_default |>
    count(default_ccsr_category_ip, sort = TRUE) |>
    left_join(
      ccsr_descriptions,
      by = c("default_ccsr_category_ip" = "ccsr_code")
    )
  
  print(principal_dx_analysis)
}

# ============================================================================
# Example 4: Trend Analysis Integration (Section 3.4)
# ============================================================================

# Download HCUP Summary Trend Table
trend_table <- download_trend_tables("2a")

# Read National-level data
national_data <- read_trend_table(trend_table, sheet = "National", as_data_table = FALSE)

# Map patient data to CCSR categories
patient_mapped <- ccsr_map(patient_data, "icd10_code", dx_map, default_only = TRUE)

# Create patient summary for comparison
patient_summary <- patient_mapped |>
  count(default_ccsr_category_ip)

# Note: Trend table column names may vary. Adjust the join column name
# based on the actual structure of the downloaded trend table.
# This example demonstrates the workflow; actual column names should be
# verified by inspecting the national_data object.

# Attempt to find matching column for join
trend_cols <- names(national_data)
potential_match <- grep("ccsr|category", trend_cols, ignore.case = TRUE, value = TRUE)

if (length(potential_match) > 0) {
  comparison <- patient_summary |>
    left_join(national_data, by = setNames(potential_match[1], "default_ccsr_category_ip"))
  
  print(head(comparison))
}
