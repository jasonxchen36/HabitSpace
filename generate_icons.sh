#!/bin/bash

# HabitSpace App Icon Generator
# Usage: ./generate_icons.sh <source_image.png>
#
# This script generates all required iOS app icon sizes from a single 1024x1024 source image.
# Requires: ImageMagick (install with: brew install imagemagick)

SOURCE_IMAGE="$1"
OUTPUT_DIR="Assets.xcassets/AppIcon.appiconset"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "Usage: ./generate_icons.sh <source_image.png>"
    echo "The source image should be 1024x1024 pixels"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed."
    echo "Install it with: brew install imagemagick"
    exit 1
fi

echo "Generating app icons from: $SOURCE_IMAGE"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# iPhone icons
convert "$SOURCE_IMAGE" -resize 40x40 "$OUTPUT_DIR/Icon-20@2x.png"
convert "$SOURCE_IMAGE" -resize 60x60 "$OUTPUT_DIR/Icon-20@3x.png"
convert "$SOURCE_IMAGE" -resize 58x58 "$OUTPUT_DIR/Icon-29@2x.png"
convert "$SOURCE_IMAGE" -resize 87x87 "$OUTPUT_DIR/Icon-29@3x.png"
convert "$SOURCE_IMAGE" -resize 80x80 "$OUTPUT_DIR/Icon-40@2x.png"
convert "$SOURCE_IMAGE" -resize 120x120 "$OUTPUT_DIR/Icon-40@3x.png"
convert "$SOURCE_IMAGE" -resize 120x120 "$OUTPUT_DIR/Icon-60@2x.png"
convert "$SOURCE_IMAGE" -resize 180x180 "$OUTPUT_DIR/Icon-60@3x.png"

# iPad icons
convert "$SOURCE_IMAGE" -resize 20x20 "$OUTPUT_DIR/Icon-20.png"
convert "$SOURCE_IMAGE" -resize 40x40 "$OUTPUT_DIR/Icon-20@2x-ipad.png"
convert "$SOURCE_IMAGE" -resize 29x29 "$OUTPUT_DIR/Icon-29.png"
convert "$SOURCE_IMAGE" -resize 58x58 "$OUTPUT_DIR/Icon-29@2x-ipad.png"
convert "$SOURCE_IMAGE" -resize 40x40 "$OUTPUT_DIR/Icon-40.png"
convert "$SOURCE_IMAGE" -resize 80x80 "$OUTPUT_DIR/Icon-40@2x-ipad.png"
convert "$SOURCE_IMAGE" -resize 76x76 "$OUTPUT_DIR/Icon-76.png"
convert "$SOURCE_IMAGE" -resize 152x152 "$OUTPUT_DIR/Icon-76@2x.png"
convert "$SOURCE_IMAGE" -resize 167x167 "$OUTPUT_DIR/Icon-83.5@2x.png"

# App Store icon
convert "$SOURCE_IMAGE" -resize 1024x1024 "$OUTPUT_DIR/Icon-1024.png"

echo "✅ All icons generated successfully!"
echo ""
echo "Generated icons:"
ls -la "$OUTPUT_DIR"/*.png
