#!/usr/bin/env Rscript
# Generate HCUPtools hex sticker logo
# This script creates the package logo with "HCUPtools" text

library(hexSticker)
library(ggplot2)

# Create the plot with ICD and CCSR hexagons
p <- ggplot() + 
  theme_void() + 
  theme_transparent() + 
  # Blue ICD hexagon
  geom_point(aes(x = 2, y = 3), size = 25, color = '#FFFFFF', fill = '#4A90E2', 
             shape = 21, stroke = 1.5) + 
  geom_text(aes(x = 2, y = 3), label = 'ICD', color = '#FFFFFF', size = 3.5, 
            fontface = 'bold', family = 'sans') + 
  # Green CCSR hexagon
  geom_point(aes(x = 4, y = 3), size = 25, color = '#FFFFFF', fill = '#50C878', 
             shape = 21, stroke = 1.5) + 
  geom_text(aes(x = 4, y = 3), label = 'CCSR', color = '#FFFFFF', size = 2.8, 
            fontface = 'bold', family = 'sans') + 
  # Connecting line
  geom_segment(aes(x = 2.6, y = 3, xend = 3.4, yend = 3), color = '#FFFFFF', 
               linewidth = 2.5, lineend = 'round', alpha = 0.9) + 
  xlim(0, 6) + 
  ylim(0, 6)

# Generate the hex sticker
# IMPORTANT: package = 'HCUPtools' sets the text at the bottom
sticker(
  p, 
  package = 'HCUPtools',  # THIS IS THE TEXT THAT APPEARS AT THE BOTTOM
  p_size = 9,             # Text size
  p_y = 0.65,             # Vertical position (lower = closer to bottom)
  p_color = '#FFFFFF',    # Text color (white)
  p_family = 'sans',      # Font family
  p_fontface = 'bold',    # Bold text
  h_fill = '#1a1a1a',     # Hexagon fill color (dark gray/black)
  h_color = '#FFFFFF',    # Hexagon border color (white)
  s_x = 1,                # Subplot x position
  s_y = 1.2,              # Subplot y position (moved up to make room for text)
  s_width = 1.2,          # Subplot width
  s_height = 1.2,         # Subplot height
  dpi = 300,              # Higher DPI for better quality
  filename = 'man/figures/HCUPtools.png'
)

cat("✅ Logo generated successfully!\n")
cat("   File: man/figures/HCUPtools.png\n")
cat("   Package name: HCUPtools\n")
cat("   Text position: Bottom (p_y = 0.65)\n")
cat("   Text size: 9\n")

