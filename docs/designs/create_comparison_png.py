from PIL import Image, ImageDraw, ImageFont
import os

OUT_DIR = 'D:/Produktivitas/terrapoint/designs/comparison'
p1 = os.path.join(OUT_DIR, "dashboard_01_existing_dark.png")
p2 = os.path.join(OUT_DIR, "dashboard_02_planning_clean_tech.png")

im1 = Image.open(p1)
im2 = Image.open(p2)

# Dimensions
w = im1.width
h = im1.height

# Create a side-by-side or stacked comparative artboard
# Stacked: Top = Existing Dark Command Center, Bottom = Planning Clean Modern Tech
header_h = 140
gap = 50
padding = 40

total_w = w + (padding * 2)
total_h = (h * 2) + (header_h * 2) + gap + (padding * 2)

canvas = Image.new("RGB", (total_w, total_h), color=(8, 11, 16))
draw = ImageDraw.Draw(canvas)

# Fonts
try:
    font_title = ImageFont.truetype("arial.ttf", 36)
    font_sub = ImageFont.truetype("arial.ttf", 20)
    font_banner = ImageFont.truetype("arial.ttf", 28)
except:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()
    font_banner = ImageFont.load_default()

# Main Top Title
draw.text((padding, padding), "TERRAPOINT WEB DASHBOARD — VISUAL COMPARISON", fill=(245, 158, 11), font=font_title)
draw.text((padding, padding + 48), "Perbandingan Tampilan Antarmuka: Existing Dark Command Center vs Planning Clean Modern Tech", fill=(148, 163, 184), font=font_sub)

# Section 1: Existing Dark
y1_banner = padding + header_h - 40
draw.rectangle([(padding, y1_banner), (padding + 800, y1_banner + 46)], fill=(27, 35, 51))
draw.text((padding + 16, y1_banner + 8), "OPSI A: EXISTING (COMMAND CENTER CARBON GELAP)", fill=(248, 250, 252), font=font_banner)
y1_img = y1_banner + 56
canvas.paste(im1, (padding, y1_img))

# Section 2: Planning Clean Modern Tech
y2_banner = y1_img + h + gap
draw.rectangle([(padding, y2_banner), (padding + 880, y2_banner + 46)], fill=(217, 119, 6))
draw.text((padding + 16, y2_banner + 8), "OPSI B: PLANNING (CLEAN MODERN TECH — PURE SLATE & NAVY)", fill=(15, 23, 42), font=font_banner)
y2_img = y2_banner + 56
canvas.paste(im2, (padding, y2_img))

out_comparison = os.path.join(OUT_DIR, "dashboard_comparison_existing_vs_planning.png")
canvas.save(out_comparison, quality=92)
print(f"Comparison PNG successfully generated at: {out_comparison}")
print(f"Size: {canvas.width} x {canvas.height} px")
