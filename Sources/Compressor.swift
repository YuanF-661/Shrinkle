import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

/// 一项压缩任务（纯数据，可跨线程传递）
struct CompressJob: Sendable {
    let id: UUID
    let url: URL
    let originalBytes: Int
    let crop: CGRect?          // 归一化 (0...1) 坐标，左上角为原点；nil 表示不裁剪
    let previousOutput: URL?   // 之前压缩生成的文件，重新压缩时直接覆盖
}

struct CompressOutput: Sendable {
    let url: URL
    let bytes: Int
    let pixelWidth: Int
    let pixelHeight: Int
}

enum CompressError: LocalizedError {
    case unreadable, encodeFailed, writeFailed(String)
    var errorDescription: String? {
        switch self {
        case .unreadable: return "Can't read image"
        case .encodeFailed: return "Encoding failed"
        case .writeFailed(let m): return "Couldn't save: \(m)"
        }
    }
}

enum Compressor {
    static let maxQuality = 0.92
    /// 质量低于这个值画面会明显变差，此时改为缩小尺寸
    static let minQuality = 0.55

    // MARK: - 读取

    /// 读取图片的像素尺寸（已按 EXIF 方向修正）
    static func orientedPixelSize(url: URL) -> CGSize? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let p = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = p[kCGImagePropertyPixelWidth] as? Int,
              let h = p[kCGImagePropertyPixelHeight] as? Int else { return nil }
        let o = p[kCGImagePropertyOrientation] as? Int ?? 1
        return (5...8).contains(o) ? CGSize(width: h, height: w) : CGSize(width: w, height: h)
    }

    /// 读取图片并按 EXIF 方向转正。maxPixel 为 nil 时读取原始尺寸。
    static func loadOriented(url: URL, maxPixel: Int? = nil) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
        return loadOriented(source: src, maxPixel: maxPixel)
    }

    static func loadOriented(source src: CGImageSource, maxPixel: Int?) -> CGImage? {
        var limit = maxPixel
        if limit == nil,
           let p = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
           let w = p[kCGImagePropertyPixelWidth] as? Int,
           let h = p[kCGImagePropertyPixelHeight] as? Int {
            limit = max(w, h)
        }
        var opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        if let limit { opts[kCGImageSourceThumbnailMaxPixelSize] = limit }
        return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    }

    // MARK: - 压缩主流程

    static func compress(_ job: CompressJob, fraction: Double, outputDir: URL?) throws -> CompressOutput {
        guard let src = CGImageSourceCreateWithURL(job.url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              var img = loadOriented(source: src, maxPixel: nil) else { throw CompressError.unreadable }

        var areaFraction = 1.0
        if let c = job.crop {
            let r = CGRect(x: c.minX * CGFloat(img.width), y: c.minY * CGFloat(img.height),
                           width: c.width * CGFloat(img.width), height: c.height * CGFloat(img.height)).integral
            if let cropped = img.cropping(to: r) {
                areaFraction = Double(cropped.width * cropped.height) / Double(img.width * img.height)
                img = cropped
            }
        }

        // JPG 不支持透明，透明背景铺白色
        if hasAlpha(img), let flat = redraw(img, width: img.width, height: img.height) {
            img = flat
        }

        // 目标体积：原文件 × 百分比（裁剪后按剩余面积等比例缩小目标）
        let target = max(8_000, Int(Double(job.originalBytes) * fraction * areaFraction))
        let meta = metadata(from: src)
        guard let (data, finalImg) = encode(img, toFit: target, meta: meta) else { throw CompressError.encodeFailed }

        let dest = outputURL(for: job, outputDir: outputDir)
        do {
            try data.write(to: dest, options: .atomic)
        } catch {
            throw CompressError.writeFailed(error.localizedDescription)
        }
        return CompressOutput(url: dest, bytes: data.count, pixelWidth: finalImg.width, pixelHeight: finalImg.height)
    }

    /// 先尝试只降低 JPG 质量；如果质量降到 minQuality 还超出目标，就按比例缩小尺寸再试。
    static func encode(_ start: CGImage, toFit target: Int, meta: [CFString: Any]) -> (Data, CGImage)? {
        var img = start
        for _ in 0..<8 {
            guard let hi = jpeg(img, quality: maxQuality, meta: meta) else { return nil }
            if hi.count <= target { return (hi, img) }

            guard let lo = jpeg(img, quality: minQuality, meta: meta) else { return nil }
            if lo.count <= target {
                // 二分查找满足目标的最高质量
                var a = minQuality, b = maxQuality, best = lo
                for _ in 0..<6 {
                    let m = (a + b) / 2
                    guard let d = jpeg(img, quality: m, meta: meta) else { break }
                    if d.count <= target { best = d; a = m } else { b = m }
                }
                return (best, img)
            }

            // 缩小尺寸：体积大致与像素数成正比
            let f = min(0.92, max(0.3, (Double(target) / Double(lo.count)).squareRoot() * 0.97))
            let w = Int(Double(img.width) * f), h = Int(Double(img.height) * f)
            guard w >= 64, h >= 64, let smaller = redraw(img, width: w, height: h) else { return (lo, img) }
            img = smaller
        }
        guard let last = jpeg(img, quality: minQuality, meta: meta) else { return nil }
        return (last, img)
    }

    // MARK: - 工具

    static func jpeg(_ img: CGImage, quality: Double, meta: [CFString: Any]) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        var props = meta
        props[kCGImageDestinationLossyCompressionQuality] = quality
        CGImageDestinationAddImage(dest, img, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    /// 保留拍摄时间、相机型号等 EXIF 信息；去掉 GPS 位置（隐私）；方向已转正。
    static func metadata(from src: CGImageSource) -> [CFString: Any] {
        guard let p = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else { return [:] }
        var out: [CFString: Any] = [kCGImagePropertyOrientation: 1]
        if var exif = p[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            exif.removeValue(forKey: kCGImagePropertyExifPixelXDimension)
            exif.removeValue(forKey: kCGImagePropertyExifPixelYDimension)
            out[kCGImagePropertyExifDictionary] = exif
        }
        if var tiff = p[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            tiff[kCGImagePropertyTIFFOrientation] = 1
            out[kCGImagePropertyTIFFDictionary] = tiff
        }
        return out
    }

    static func hasAlpha(_ img: CGImage) -> Bool {
        switch img.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: return true
        default: return false
        }
    }

    /// 重新绘制（缩放 / 去透明），白色背景
    static func redraw(_ img: CGImage, width: Int, height: Int) -> CGImage? {
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
        let preferred = (img.colorSpace?.model == .rgb) ? img.colorSpace! : srgb
        func draw(in space: CGColorSpace) -> CGImage? {
            guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.setFillColor(CGColor(gray: 1, alpha: 1))
            ctx.fill(rect)
            ctx.interpolationQuality = .high
            ctx.draw(img, in: rect)
            return ctx.makeImage()
        }
        return draw(in: preferred) ?? draw(in: srgb)
    }

    static func outputURL(for job: CompressJob, outputDir: URL?) -> URL {
        let dir = outputDir ?? job.url.deletingLastPathComponent()
        if let prev = job.previousOutput,
           prev.deletingLastPathComponent().standardizedFileURL == dir.standardizedFileURL {
            return prev
        }
        let base = job.url.deletingPathExtension().lastPathComponent + "_compressed"
        var candidate = dir.appendingPathComponent(base + ".jpg")
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base)-\(n).jpg")
            n += 1
        }
        return candidate
    }
}
