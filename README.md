# Shrinkle

A simple, no-fuss macOS app for shrinking phone photos. Drag your photos in and compress them to **20%** of their original file size in one click (adjustable). Every photo is saved as a JPG.

## When you'll need it

Phone photos are often 3–10 MB and frequently in HEIC format, which a lot of places won't accept:

- **"Image too large" on upload**: application forms, résumé attachments, visa and ID photos, and school or company portals often cap uploads at 2 MB or even 500 KB. Drop the photo in, shrink it, upload again.
- **HEIC not supported**: iPhone's default HEIC photos won't open on many websites, Windows PCs and older systems. Shrinkle converts them to universally supported JPG.
- **Email attachment limits**: a dozen full-size photos easily blow past the 20–25 MB limit. At 20% size you can send several times as many.
- **Marketplace listings**: eBay, Vinted and similar sites want lots of product photos. Batch-shrink them first for faster uploads and less mobile data.
- **Only need part of the photo**: for documents, receipts or screenshots, crop to the bit that matters, then compress. Smaller file, clearer content.
- **Freeing up space**: back from a trip with hundreds of photos? Make a small copy for sharing or backup and keep the originals untouched.
- **Casual sharing**: for family, group chats or images in documents, a 20% file looks practically the same on a phone or laptop screen.

> Tip: if a site says "max X MB", set the slider to roughly X ÷ the original size. For example, a 5 MB photo with a 1 MB limit needs about 20%.

## Features

- **Compress to a target size**: 20% of the original by default, adjustable from 5% to 90%. Shrinkle lowers the JPG quality first. If quality would drop to a point where it looks noticeably worse, it scales the image down instead, to keep it looking good.
- **Converts to JPG**: HEIC, PNG, TIFF, WebP and more are converted to JPG. Photos are rotated upright automatically and transparent backgrounds become white.
- **Optional quick crop**: click the crop icon on a row (or double-click the row). Drag the box to move it, drag the corners to resize. Choose Free, Original, 1:1, 4:3, 3:4, 16:9 or 9:16. Skip it and compression works exactly the same.
- **Batch processing**: drop in many photos or a whole folder, or drop them onto the Dock icon. Several photos are processed at once.
- **Originals stay untouched**: output is saved as `originalname_compressed.jpg` next to the original or in a folder you choose.
- **Privacy**: keeps EXIF details like capture date and camera model, but removes GPS location.

## Install

Download `Shrinkle.zip` from the [Releases](../../releases) page, unzip it, and drag `Shrinkle.app` into your Applications folder.

> Shrinkle isn't notarized by Apple. The first time you open it, **right-click the app → Open**, then confirm.

Requires macOS 13 or later. Runs natively on Apple Silicon and Intel.

> Note: the app's interface is currently in Chinese.

## Build from source

You'll need Xcode or the Command Line Tools:

```bash
git clone https://github.com/YuanF-661/Shrinkle.git
cd Shrinkle
./build.sh        # produces build/Shrinkle.app
```

## Project structure

```
Sources/
  App.swift          App entry point
  ContentView.swift  Main window: list, drag and drop, bottom toolbar
  CropView.swift     Crop editor
  Model.swift        App state and batch compression
  Compressor.swift   Load, crop and encode JPG to a target size (ImageIO)
Resources/Info.plist
scripts/make_icon.swift  Generates the app icon
build.sh                 Compiles and packages the .app
```

Built with SwiftUI and ImageIO only, with no third-party dependencies.

## License

[MIT](LICENSE)
