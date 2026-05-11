# Figure Descriptions for Healthcare Analytics Manuscript

This document describes the figures needed for the manuscript. You can create these using R (with packages like `diagram`, `DiagrammeR`, `ggplot2`), Python (with `matplotlib`, `graphviz`), or any diagramming tool.

## Figure 1: Package Architecture (package_architecture.png)

**Location**: Section 2.1

**Description**: A diagram showing the HCUPtools package architecture with:
- User interface layer (R functions)
- Core functionality modules (Download, Mapping, Trend Tables, Utilities)
- Data flow from HCUP website → Package → User
- Key dependencies (httr2, dplyr, readr, etc.)
- Caching layer

**Suggested Layout**: Top-down flow diagram showing:
```
User → HCUPtools Functions → Core Modules → HCUP Website
                              ↓
                         Cache Layer
```

## Figure 2: Workflow Comparison (workflow_comparison.png)

**Location**: Section 1 (Introduction)

**Description**: Side-by-side comparison showing:
- **Left side (Manual)**: Multiple steps with arrows: Navigate website → Download ZIP → Extract → Process CSV → Format data → Manual version tracking → Manual citation
- **Right side (Automated)**: Single step: `download_ccsr()` → `ccsr_map()` → Analysis ready

**Visual Style**: Two columns, manual process shown as complex with many steps, automated as streamlined.

## Figure 3: Output Format Comparison (output_formats.png)

**Location**: Section 2.2.2

**Description**: Three panels showing example data:
- **Panel A (Long format)**: Show same ICD-10 code appearing multiple times with different CCSR categories
- **Panel B (Wide format)**: Show one row with multiple CCSR columns (CCSR_1, CCSR_2, etc.)
- **Panel C (Default only)**: Show one row with single CCSR category

**Example data to illustrate** (per HCUP diagnosis CCSR reference mapping):
- ICD-10-CM code: **E11.0** (Type 2 diabetes mellitus with hyperosmolarity)
- Assigned categories include **END002** (default inpatient) and **END005**
- Show how each format represents this differently; long format uses ICD and CCSR **side by side**

## Figure 4: HCUPtools Workflow (hcuptools_workflow.png)

**Location**: Section 3 (Results)

**Description**: Complete workflow diagram showing:
1. Download CCSR mapping files
2. Download Trend Tables (optional)
3. Map ICD-10 codes to CCSR categories
4. Perform analysis (descriptive, diagnostic, predictive, prescriptive)
5. Generate citations

**Style**: Flowchart with decision points and different analytical paths.

## Figure 5: Performance Comparison (performance_comparison.png)

**Location**: Section 3.5

**Description**: Bar chart or grouped bar chart comparing:
- **Manual workflow** (blue bars): Time for each task
  - Website navigation: 15-20 min
  - File download/extraction: 10-15 min
  - Data processing: 30-45 min
  - Cross-classification handling: 20-30 min
  - Version management: 10-15 min
  - Citation generation: 5-10 min
  - **Total: 90-135 minutes**

- **HCUPtools workflow** (green bars): Time for each task
  - Website navigation: 0 min (automated)
  - File download/extraction: 1-2 min (automated)
  - Data processing: 1-2 min (automated)
  - Cross-classification handling: 1-2 min (automated)
  - Version management: 0 min (automated)
  - Citation generation: 0 min (automated)
  - **Total: 3-6 minutes**

**Style**: Grouped bar chart with time on y-axis, tasks on x-axis.

---

## Tools for Creating Figures

### Option 1: R with DiagrammeR
```r
library(DiagrammeR)
# Create flowchart diagrams
```

### Option 2: R with ggplot2
```r
library(ggplot2)
# Create bar charts and comparisons
```

### Option 3: Python with matplotlib
```python
import matplotlib.pyplot as plt
# Create all figure types
```

### Option 4: Online Tools
- draw.io (diagrams.net)
- Lucidchart
- Canva (for simple diagrams)

### Option 5: LaTeX/TikZ
If converting to PDF, TikZ can create professional diagrams.

---

## Figure Specifications

- **Format**: PNG or PDF (high resolution)
- **Resolution**: Minimum 300 DPI for publication
- **Dimensions**: 
  - Single column: ~3.5 inches wide
  - Full width: ~7 inches wide
- **Font size**: Minimum 10pt, readable when scaled
- **Colors**: Use colorblind-friendly palettes
- **File naming**: As specified above (package_architecture.png, etc.)

---

## Quick R Script Template for Performance Comparison

```r
library(ggplot2)
library(dplyr)

# Create data
tasks <- c("Website\nNavigation", "Download/\nExtraction", 
           "Data\nProcessing", "Cross-\nClassification", 
           "Version\nManagement", "Citation\nGeneration")

manual_time <- c(17.5, 12.5, 37.5, 25, 12.5, 7.5)  # minutes
automated_time <- c(0, 1.5, 1.5, 1.5, 0, 0)

df <- data.frame(
  Task = rep(tasks, 2),
  Time = c(manual_time, automated_time),
  Method = rep(c("Manual", "HCUPtools"), each = 6)
)

# Create plot
ggplot(df, aes(x = Task, y = Time, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("Manual" = "#4472C4", 
                               "HCUPtools" = "#70AD47")) +
  labs(x = "Task", y = "Time (minutes)", 
       title = "Time Comparison: Manual vs Automated Workflow") +
  theme_minimal() +
  theme(legend.position = "top")

ggsave("figures/performance_comparison.png", width = 8, height = 5, dpi = 300)
```

