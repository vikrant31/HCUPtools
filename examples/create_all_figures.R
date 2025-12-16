# Generate Figures for HCUPtools Manuscript
# This script creates all figures used in the SoftwareX manuscript

library(ggplot2)
library(dplyr)
library(grid)
library(gridExtra)

# Set output directory
fig_dir <- "figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir)

# ============================================================================
# Figure 1: Package Architecture
# ============================================================================

p1 <- ggplot(data.frame(x = 0, y = 0), aes(x = x, y = y)) +
  annotate("rect", xmin = 0.1, xmax = 0.9, ymin = 0.85, ymax = 0.95, 
           fill = "#E3F2FD", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.9, label = "User (R Console)", size = 5, fontface = "bold") +
  
  annotate("rect", xmin = 0.1, xmax = 0.9, ymin = 0.65, ymax = 0.8, 
           fill = "#BBDEFB", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.75, label = "HCUPtools Functions", size = 5, fontface = "bold") +
  annotate("text", x = 0.5, y = 0.7, label = "download_ccsr() | ccsr_map() | download_trend_tables()", size = 3.5) +
  
  annotate("rect", xmin = 0.15, xmax = 0.45, ymin = 0.4, ymax = 0.6, 
           fill = "#90CAF9", color = "black", size = 1) +
  annotate("text", x = 0.3, y = 0.52, label = "Download\nModule", size = 4, fontface = "bold") +
  annotate("text", x = 0.3, y = 0.48, label = "httr2 | xml2", size = 3) +
  
  annotate("rect", xmin = 0.55, xmax = 0.85, ymin = 0.4, ymax = 0.6, 
           fill = "#90CAF9", color = "black", size = 1) +
  annotate("text", x = 0.7, y = 0.52, label = "Processing\nModule", size = 4, fontface = "bold") +
  annotate("text", x = 0.7, y = 0.48, label = "dplyr | tidyr | readr", size = 3) +
  
  annotate("rect", xmin = 0.1, xmax = 0.9, ymin = 0.2, ymax = 0.35, 
           fill = "#64B5F6", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.3, label = "Intelligent Caching Layer", size = 4, fontface = "bold") +
  
  annotate("rect", xmin = 0.1, xmax = 0.9, ymin = 0.05, ymax = 0.15, 
           fill = "#42A5F5", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.1, label = "HCUP Website (AHRQ)", size = 5, fontface = "bold", color = "white") +
  
  annotate("segment", x = 0.5, xend = 0.5, y = 0.85, yend = 0.8, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.5, xend = 0.3, y = 0.65, yend = 0.6, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.5, xend = 0.7, y = 0.65, yend = 0.6, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.3, xend = 0.5, y = 0.4, yend = 0.35, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.7, xend = 0.5, y = 0.4, yend = 0.35, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.2, yend = 0.15, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  
  xlim(0, 1) + ylim(0, 1) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white"))

ggsave(file.path(fig_dir, "package_architecture.png"), p1, 
       width = 8, height = 6, dpi = 300)

# ============================================================================
# Figure 2: Workflow Comparison
# ============================================================================

p2 <- ggplot(data.frame(x = 0, y = 0), aes(x = x, y = y)) +
  annotate("text", x = 0.5, y = 0.95, label = "Workflow Comparison", 
           size = 7, fontface = "bold", hjust = 0.5) +
  
  annotate("rect", xmin = 0.05, xmax = 0.48, ymin = 0.05, ymax = 0.85, 
           fill = "#FFEBEE", color = "#D32F2F", size = 2) +
  annotate("text", x = 0.265, y = 0.82, label = "Manual Workflow", 
           size = 6, fontface = "bold", color = "#D32F2F") +
  
  manual_steps <- c("1. Navigate HCUP\n   website", 
                    "2. Download ZIP\n   files", 
                    "3. Extract files\n   manually",
                    "4. Process CSV\n   files",
                    "5. Handle cross-\n   classifications",
                    "6. Manage versions\n   manually",
                    "7. Generate citations\n   manually")
  y_positions <- seq(0.75, 0.15, length.out = 7)
  
  for(i in 1:7) {
    annotate("rect", xmin = 0.08, xmax = 0.45, ymin = y_positions[i] - 0.06, 
             ymax = y_positions[i] + 0.02, fill = "white", color = "gray", size = 0.5) +
    annotate("text", x = 0.265, y = y_positions[i] - 0.02, 
             label = manual_steps[i], size = 3.5, hjust = 0.5)
    if(i < 7) {
      annotate("segment", x = 0.265, xend = 0.265, 
               y = y_positions[i] - 0.06, yend = y_positions[i+1] + 0.02,
               arrow = arrow(length = unit(0.15, "cm")), color = "#D32F2F", size = 1)
    }
  }
  
  annotate("rect", xmin = 0.52, xmax = 0.95, ymin = 0.05, ymax = 0.85, 
           fill = "#E8F5E9", color = "#388E3C", size = 2) +
  annotate("text", x = 0.735, y = 0.82, label = "HCUPtools Workflow", 
           size = 6, fontface = "bold", color = "#388E3C") +
  
  auto_steps <- c("1. download_ccsr()", 
                  "2. ccsr_map()", 
                  "3. Analysis Ready!")
  y_positions_auto <- seq(0.65, 0.25, length.out = 3)
  
  for(i in 1:3) {
    annotate("rect", xmin = 0.55, xmax = 0.92, ymin = y_positions_auto[i] - 0.08, 
             ymax = y_positions_auto[i] + 0.08, fill = "white", color = "gray", size = 0.5) +
    annotate("text", x = 0.735, y = y_positions_auto[i], 
             label = auto_steps[i], size = 4.5, hjust = 0.5, fontface = "bold")
    if(i < 3) {
      annotate("segment", x = 0.735, xend = 0.735, 
               y = y_positions_auto[i] - 0.08, yend = y_positions_auto[i+1] + 0.08,
               arrow = arrow(length = unit(0.2, "cm")), color = "#388E3C", size = 1.5)
    }
  }
  
  annotate("text", x = 0.265, y = 0.08, label = "~2-3 hours", 
           size = 4, fontface = "bold", color = "#D32F2F") +
  annotate("text", x = 0.735, y = 0.08, label = "~5-10 minutes", 
           size = 4, fontface = "bold", color = "#388E3C") +
  
  xlim(0, 1) + ylim(0, 1) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white"))

ggsave(file.path(fig_dir, "workflow_comparison.png"), p2, 
       width = 10, height = 7, dpi = 300)

# ============================================================================
# Figure 3: Output Format Comparison
# ============================================================================

panel_a <- ggplot(data.frame(x = 0, y = 0), aes(x = x, y = y)) +
  annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, 
           fill = "#E3F2FD", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.95, label = "(A) Long Format", 
           size = 5, fontface = "bold") +
  annotate("text", x = 0.5, y = 0.8, label = "ICD10", size = 4, fontface = "bold") +
  annotate("text", x = 0.5, y = 0.7, label = "E11.9", size = 3.5) +
  annotate("text", x = 0.5, y = 0.6, label = "E11.9", size = 3.5) +
  annotate("text", x = 0.5, y = 0.5, label = "CCSR", size = 4, fontface = "bold") +
  annotate("text", x = 0.5, y = 0.4, label = "END001", size = 3.5) +
  annotate("text", x = 0.5, y = 0.3, label = "MBD001", size = 3.5) +
  annotate("text", x = 0.5, y = 0.15, label = "One row per\nICD-10 per CCSR", 
           size = 3, hjust = 0.5) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white"))

panel_b <- ggplot(data.frame(x = 0, y = 0), aes(x = x, y = y)) +
  annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, 
           fill = "#E8F5E9", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.95, label = "(B) Wide Format", 
           size = 5, fontface = "bold") +
  annotate("text", x = 0.25, y = 0.8, label = "ICD10", size = 4, fontface = "bold") +
  annotate("text", x = 0.5, y = 0.8, label = "CCSR_1", size = 4, fontface = "bold") +
  annotate("text", x = 0.75, y = 0.8, label = "CCSR_2", size = 4, fontface = "bold") +
  annotate("text", x = 0.25, y = 0.5, label = "E11.9", size = 3.5) +
  annotate("text", x = 0.5, y = 0.5, label = "END001", size = 3.5) +
  annotate("text", x = 0.75, y = 0.5, label = "MBD001", size = 3.5) +
  annotate("text", x = 0.5, y = 0.15, label = "One row per\nICD-10 code", 
           size = 3, hjust = 0.5) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white"))

panel_c <- ggplot(data.frame(x = 0, y = 0), aes(x = x, y = y)) +
  annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, 
           fill = "#FFF3E0", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.95, label = "(C) Default Only", 
           size = 5, fontface = "bold") +
  annotate("text", x = 0.35, y = 0.7, label = "ICD10", size = 4, fontface = "bold") +
  annotate("text", x = 0.65, y = 0.7, label = "CCSR", size = 4, fontface = "bold") +
  annotate("text", x = 0.35, y = 0.4, label = "E11.9", size = 3.5) +
  annotate("text", x = 0.65, y = 0.4, label = "END001", size = 3.5) +
  annotate("text", x = 0.5, y = 0.15, label = "One-to-one\nmapping", 
           size = 3, hjust = 0.5) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white"))

p3 <- grid.arrange(panel_a, panel_b, panel_c, ncol = 3, 
                   top = textGrob("Output Format Comparison", 
                                  gp = gpar(fontsize = 14, fontface = "bold")))

ggsave(file.path(fig_dir, "output_formats.png"), p3, 
       width = 12, height = 4, dpi = 300)

# ============================================================================
# Figure 4: HCUPtools Workflow
# ============================================================================

p4 <- ggplot(data.frame(x = 0, y = 0), aes(x = x, y = y)) +
  annotate("text", x = 0.5, y = 0.95, label = "HCUPtools Complete Workflow", 
           size = 7, fontface = "bold", hjust = 0.5) +
  
  annotate("rect", xmin = 0.1, xmax = 0.4, ymin = 0.75, ymax = 0.85, 
           fill = "#E3F2FD", color = "black", size = 1) +
  annotate("text", x = 0.25, y = 0.8, label = "1. Download CCSR\nMapping Files", 
           size = 4, hjust = 0.5, fontface = "bold") +
  
  annotate("rect", xmin = 0.6, xmax = 0.9, ymin = 0.75, ymax = 0.85, 
           fill = "#E3F2FD", color = "black", size = 1) +
  annotate("text", x = 0.75, y = 0.8, label = "2. Download Trend\nTables (optional)", 
           size = 4, hjust = 0.5, fontface = "bold") +
  
  annotate("rect", xmin = 0.35, xmax = 0.65, ymin = 0.55, ymax = 0.65, 
           fill = "#BBDEFB", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.6, label = "3. Map ICD-10 Codes\nto CCSR Categories", 
           size = 4, hjust = 0.5, fontface = "bold") +
  
  annotate("rect", xmin = 0.2, xmax = 0.8, ymin = 0.35, ymax = 0.5, 
           fill = "#90CAF9", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.45, label = "4. Perform Analysis", 
           size = 5, hjust = 0.5, fontface = "bold") +
  annotate("text", x = 0.25, y = 0.38, label = "Descriptive", size = 3.5) +
  annotate("text", x = 0.4, y = 0.38, label = "Diagnostic", size = 3.5) +
  annotate("text", x = 0.55, y = 0.38, label = "Predictive", size = 3.5) +
  annotate("text", x = 0.7, y = 0.38, label = "Prescriptive", size = 3.5) +
  
  annotate("rect", xmin = 0.35, xmax = 0.65, ymin = 0.15, ymax = 0.25, 
           fill = "#64B5F6", color = "black", size = 1) +
  annotate("text", x = 0.5, y = 0.2, label = "5. Generate Citations", 
           size = 4, hjust = 0.5, fontface = "bold") +
  
  annotate("segment", x = 0.25, xend = 0.5, y = 0.75, yend = 0.65, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.75, xend = 0.5, y = 0.75, yend = 0.65, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.55, yend = 0.5, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.35, yend = 0.25, 
           arrow = arrow(length = unit(0.2, "cm")), size = 1) +
  
  xlim(0, 1) + ylim(0, 1) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white"))

ggsave(file.path(fig_dir, "hcuptools_workflow.png"), p4, 
       width = 10, height = 7, dpi = 300)

# ============================================================================
# Figure 5: Performance Comparison
# ============================================================================

tasks <- c("Website\nNavigation", "Download/\nExtraction", 
           "Data\nProcessing", "Cross-\nClassification", 
           "Version\nManagement", "Citation\nGeneration")

manual_time <- c(17.5, 12.5, 37.5, 25, 12.5, 7.5)
automated_time <- c(0, 1.5, 1.5, 1.5, 0, 0)

df_perf <- data.frame(
  Task = factor(rep(tasks, 2), levels = tasks),
  Time = c(manual_time, automated_time),
  Method = rep(c("Manual", "HCUPtools"), each = 6)
)

p5 <- ggplot(df_perf, aes(x = Task, y = Time, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("Manual" = "#4472C4", 
                               "HCUPtools" = "#70AD47")) +
  labs(x = "Task", y = "Time (minutes)", 
       title = "Time Comparison: Manual vs Automated Workflow",
       fill = "Method") +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    axis.title = element_text(face = "bold")
  ) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5)

ggsave(file.path(fig_dir, "performance_comparison.png"), p5, 
       width = 10, height = 6, dpi = 300)
