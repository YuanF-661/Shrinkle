#!/bin/bash
# Re-render the app icon (Resources/AppIcon.png) and README images (docs/assets/).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
SRC=$(ls Sources/*.swift | grep -v App.swift)
swiftc -O -swift-version 5 $SRC scripts/assets/*.swift -o build/render_assets
build/render_assets "$PWD"

# Posters have no transparency: ship them as JPG to keep the repo light
for f in hero before-after too-large crop social-preview; do
  sips -s format jpeg -s formatOptions 85 "docs/assets/$f.png" --out "docs/assets/$f.jpg" >/dev/null
  rm "docs/assets/$f.png"
done
