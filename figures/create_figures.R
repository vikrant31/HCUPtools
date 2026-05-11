# R Script to Create Figures for Healthcare Analytics Manuscript
# Run this script to generate all figures

library(ggplot2)
library(dplyr)
library(gridExtra)

# Set output directory
fig_dir <- "figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir)

# ============================================================================
# Figure 5: Performance Comparison
# ============================================================================

tasks <- c("Website\nNavigation", "Download/\nExtraction", 
           "Data\nProcessing", "Cross-\nClassification", 
           "Version\nManagement", "Citation\nGeneration")

manual_time <- c(17.5, 12.5, 37.5, 25, 12.5, 7.5)  # minutes
automated_time <- c(0, 1.5, 1.5, 1.5, 0, 0)

df_perf <- data.frame(
  Task = factor(rep(tasks, 2), levels = tasks),
  Time = c(manual_time, automated_time),
  Method = rep(c("Manual", "HCUPtools"), each = 6)
)

p1 <- ggplot(df_perf, aes(x = Task, y = Time, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("Manual" = "#4472C4", 
                               "HCUPtools" = "#70AD47")) +
  labs(x = "Task", y = "Time (minutes)", 
       title = "Time Comparison: Manual vs Automated Workflow",
       fill = "Method") +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5)

ggsave(file.path(fig_dir, "performance_comparison.png"), 
       p1, width = 8, height = 5, dpi = 300)

# ============================================================================
# Figure 3: Output Format Comparison (Example Data Visualization)
# ============================================================================

# Create example data showing different formats
example_icd <- "E11.9"
example_ccsr <- c("END001", "MBD001")

# Long format example
long_data <- data.frame(
  ICD10 = rep(example_icd, 2),
  CCSR = example_ccsr,
  Description = c("Diabetes", "Metabolic disorders")
)

# Wide format example
wide_data <- data.frame(
  ICD10 = example_icd,
  CCSR_1 = example_ccsr[1],
  CCSR_2 = example_ccsr[2]
)

# Default format example
default_data <- data.frame(
  ICD10 = example_icd,
  CCSR = example_ccsr[1]  # Default category
)

# Create visualization (simplified table view)
# Note: For publication, you may want to use a more sophisticated table
# or create this in a diagramming tool

cat("Figure 3 should be created manually or with a table/diagram tool\n")
cat("showing the three different output formats side by side.\n")

# ============================================================================
# Note on Other Figures
# ============================================================================

cat("\n")
cat("Figures 1, 2, and 4 are best created using diagramming tools:\n")
cat("- draw.io (diagrams.net)\n")
cat("- Lucidchart\n")
cat("- R package 'DiagrammeR'\n")
cat("- Python with graphviz\n")
cat("\n")
cat("See Figure_Descriptions.md for detailed specifications.\n")

