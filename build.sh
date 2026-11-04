#!/bin/bash
# Build and package the Mac app: ./build.sh  ->  build/Shrinkle.app
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Shrinkle.app"
BIN="Shrinkle"
mkdir -p build

# 1. Compile a universal binary (Apple Silicon + Intel)
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -parse-as-library \
    -target "$arch-apple-macos13.0" \
    Sources/*.swift -o "build/$BIN-$arch"
done
lipo -create "build/$BIN-arm64" "build/$BIN-x86_64" -output "build/$BIN"

# 2. App icon, from Resources/AppIcon.png (re-render it with scripts/render_assets.sh)
if [ ! -f build/AppIcon.icns ] || [ Resources/AppIcon.png -nt build/AppIcon.icns ]; then
  ICONSET=build/AppIcon.iconset
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  for s in 16 32 128 256 512; do
    sips -z $s $s Resources/AppIcon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) Resources/AppIcon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o build/AppIcon.icns
fi

# 3. Assemble the .app bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "build/$BIN" "$APP/Contents/MacOS/$BIN"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# 4. Ad-hoc code signing
codesign --force --deep --sign - "$APP"

echo "Done: $APP"
