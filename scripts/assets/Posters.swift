import SwiftUI

// README images. Each poster is laid out at 1x and rendered at 2x.

struct GlowBackground: View {
    // Radial gradients instead of .blur(), which offscreen rendering does not capture
    func glow(_ c: Color, _ o: Double, _ r: CGFloat, _ x: CGFloat, _ y: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [c.opacity(o), c.opacity(o * 0.4), c.opacity(0)], center: .center, startRadius: 0, endRadius: r))
            .frame(width: r * 2, height: r * 2)
            .offset(x: x, y: y)
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1A1033), Color(hex: 0x2A1458), Color(hex: 0x0E1630)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            glow(Brand.pink, 0.55, 520, -420, -260)
            glow(Brand.orange, 0.45, 480, 480, 280)
            glow(Brand.violet, 0.6, 560, 260, -300)
        }
    }
}

struct Chip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
            Text(text).font(Brand.font(15, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.12)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.18)))
    }
}

/// A fake macOS window around a real screenshot of the app
struct WindowFrame: View {
    let image: NSImage
    let width: CGFloat
    var showToolbar = true

    var body: some View {
        let h = width * image.size.height / image.size.width
        VStack(spacing: 0) {
            ZStack {
                Color(hex: 0xF3F1F4)
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: 0xFF5F57)).frame(width: 12, height: 12)
                    Circle().fill(Color(hex: 0xFEBC2E)).frame(width: 12, height: 12)
                    Circle().fill(Color(hex: 0x28C840)).frame(width: 12, height: 12)
                    Spacer()
                    if showToolbar {
                        Image(systemName: "plus").padding(.trailing, 14)
                        Image(systemName: "trash")
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: 0x6B6B70))
                .padding(.horizontal, 16)
                Text("Shrinkle").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: 0x3A3A3C))
            }
            .frame(height: 40)
            Rectangle().fill(.black.opacity(0.08)).frame(height: 1)
            Image(nsImage: image).resizable().interpolation(.high).frame(width: width, height: h)
        }
        .frame(width: width)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.black.opacity(0.12)))
        .shadow(color: .black.opacity(0.45), radius: 40, y: 24)
    }
}

// MARK: - Hero banner

struct HeroPoster: View {
    let screenshot: NSImage
    var body: some View {
        ZStack {
            GlowBackground()
            HStack(spacing: 56) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 18) {
                        LogoMark().frame(width: 84, height: 84)
                            .shadow(color: Brand.pink.opacity(0.6), radius: 24)
                        Text("Shrinkle").font(Brand.font(72, .heavy)).foregroundStyle(.white)
                    }
                    Text("Phone photos too big?")
                        .font(Brand.font(38, .bold))
                        .foregroundStyle(LinearGradient(colors: [Brand.orange, Color(hex: 0xFF7FA3)], startPoint: .leading, endPoint: .trailing))
                    Text("Drop them in. Get them back at 20% of the size, as JPGs that open everywhere.")
                        .font(Brand.font(21, .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Chip(icon: "arrow.triangle.2.circlepath", text: "HEIC → JPG")
                            Chip(icon: "square.stack.3d.up.fill", text: "Batch")
                            Chip(icon: "crop", text: "Quick crop")
                        }
                        HStack(spacing: 10) {
                            Chip(icon: "lock.fill", text: "100% offline")
                            Chip(icon: "location.slash.fill", text: "Strips GPS")
                        }
                    }
                    .padding(.top, 6)
                }
                .frame(width: 470, alignment: .leading)

                ZStack(alignment: .bottomLeading) {
                    WindowFrame(image: screenshot, width: 620)
                    HStack(spacing: 10) {
                        Text("4.8 MB").strikethrough().foregroundStyle(.secondary)
                        Image(systemName: "arrow.right").foregroundStyle(Brand.pink)
                        Text("962 KB").foregroundStyle(Color(hex: 0x16A34A))
                    }
                    .font(Brand.font(24, .heavy))
                    .padding(.horizontal, 22).padding(.vertical, 14)
                    .background(Capsule().fill(.white))
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                    .offset(x: -36, y: 78)
                }
            }
            .padding(.horizontal, 70)
        }
        .frame(width: 1280, height: 680)
    }
}

// MARK: - Before / after

struct SizeCard: View {
    let title: String
    let format: String
    let size: String
    let fraction: CGFloat
    let good: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SceneArt(kind: 0)
                .frame(width: 420, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack {
                Text(title).font(Brand.font(17, .semibold)).foregroundStyle(Color(hex: 0x3A3A3C))
                Spacer()
                Text(format).font(Brand.font(13, .bold))
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(good ? Color(hex: 0xDCFCE7) : Color(hex: 0xFFE4E6)))
                    .foregroundStyle(good ? Color(hex: 0x15803D) : Color(hex: 0xBE123C))
            }
            Text(size).font(Brand.font(44, .heavy)).foregroundStyle(good ? Color(hex: 0x16A34A) : Color(hex: 0x1F1F24))
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0xEDEAF0))
                Capsule().fill(good ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x4ADE80), Color(hex: 0x16A34A)], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(LinearGradient(colors: [Brand.orange, Brand.pink], startPoint: .leading, endPoint: .trailing)))
                    .frame(width: 420 * fraction)
            }
            .frame(width: 420, height: 14)
        }
        .frame(width: 420)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white)
            .shadow(color: Color(hex: 0x5B2A86, opacity: 0.12), radius: 30, y: 14))
    }
}

struct BeforeAfterPoster: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF6F0), Color(hex: 0xF6F0FF)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 34) {
                VStack(spacing: 10) {
                    Text("Same photo. 80% lighter.")
                        .font(Brand.font(50, .heavy)).foregroundStyle(Color(hex: 0x1F1F24))
                    Text("Shrinkle squeezes out the bytes your screen never shows.")
                        .font(Brand.font(22, .medium)).foregroundStyle(Color(hex: 0x6B6B76))
                }
                HStack(spacing: 34) {
                    SizeCard(title: "IMG_2041.HEIC", format: "HEIC", size: "4.8 MB", fraction: 1, good: false)
                    ZStack {
                        Circle().fill(.white).frame(width: 88, height: 88)
                            .shadow(color: Color(hex: 0x5B2A86, opacity: 0.18), radius: 16, y: 8)
                        LogoMark().frame(width: 60, height: 60)
                    }
                    SizeCard(title: "IMG_2041_compressed.jpg", format: "JPG", size: "962 KB", fraction: 0.2, good: true)
                }
            }
        }
        .frame(width: 1280, height: 720)
    }
}

// MARK: - "File too large" upload story

struct UploadCard: View {
    let ok: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Upload your photo").font(Brand.font(22, .bold)).foregroundStyle(Color(hex: 0x1F1F24))
            Text("JPG or PNG, max 2 MB").font(Brand.font(15, .medium)).foregroundStyle(Color(hex: 0x8A8A94))
            HStack(spacing: 14) {
                SceneArt(kind: ok ? 1 : 1)
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(ok ? "IMG_2041_compressed.jpg" : "IMG_2041.HEIC")
                        .font(Brand.font(16, .semibold)).foregroundStyle(Color(hex: 0x2A2A30))
                    Text(ok ? "962 KB" : "4.8 MB")
                        .font(Brand.font(14, .bold))
                        .foregroundStyle(ok ? Color(hex: 0x16A34A) : Color(hex: 0xE11D48))
                }
                Spacer()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: 0xD9D6DE), style: StrokeStyle(lineWidth: 2, dash: [7, 5])))

            HStack(spacing: 10) {
                Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                Text(ok ? "Uploaded successfully" : "File is too large. Maximum size is 2 MB.")
            }
            .font(Brand.font(16, .semibold))
            .foregroundStyle(ok ? Color(hex: 0x15803D) : Color(hex: 0xBE123C))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(ok ? Color(hex: 0xDCFCE7) : Color(hex: 0xFFE4E6)))

            Text(ok ? "Continue" : "Try again")
                .font(Brand.font(17, .bold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12).fill(ok ? Color(hex: 0x2563EB) : Color(hex: 0xA1A1AA)))
        }
        .padding(28)
        .frame(width: 430)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
            .shadow(color: .black.opacity(0.35), radius: 30, y: 16))
    }
}

struct UploadPoster: View {
    var body: some View {
        ZStack {
            GlowBackground()
            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    (Text("“File too large”? ").foregroundColor(.white)
                     + Text("Not anymore.").foregroundColor(Color(hex: 0xFFB37A)))
                        .font(Brand.font(50, .heavy))
                    Text("Forms, portals, marketplaces and email all have size limits. Shrinkle gets you under them.")
                        .font(Brand.font(21, .medium)).foregroundStyle(.white.opacity(0.72))
                }
                HStack(spacing: 30) {
                    UploadCard(ok: false)
                    VStack(spacing: 12) {
                        LogoMark().frame(width: 76, height: 76)
                            .shadow(color: Brand.pink.opacity(0.7), radius: 22)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("one drop").font(Brand.font(15, .semibold)).foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(width: 130)
                    UploadCard(ok: true)
                }
            }
        }
        .frame(width: 1280, height: 720)
    }
}

// MARK: - Crop

struct CropPoster: View {
    let screenshot: NSImage
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xF6F0FF), Color(hex: 0xFFF1F4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 56) {
                VStack(alignment: .leading, spacing: 22) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.gradient)
                        Image(systemName: "crop").font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 72, height: 72)
                    Text("Crop when you need it.\nIgnore it when you don’t.")
                        .font(Brand.font(44, .heavy)).foregroundStyle(Color(hex: 0x1F1F24))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Click the crop icon on any photo. Drag to move, pull a corner to resize, or snap to 1:1, 4:3, 16:9 and more. Skip it and compression works exactly the same.")
                        .font(Brand.font(20, .medium)).foregroundStyle(Color(hex: 0x5E5E6A))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 420, alignment: .leading)
                WindowFrame(image: screenshot, width: 680, showToolbar: false)
            }
            .padding(.horizontal, 60)
        }
        .frame(width: 1280, height: 720)
    }
}

// MARK: - Social preview (GitHub "social image", 1280×640)

struct SocialPoster: View {
    var body: some View {
        ZStack {
            GlowBackground()
            VStack(spacing: 26) {
                LogoMark().frame(width: 170, height: 170)
                    .shadow(color: Brand.pink.opacity(0.6), radius: 40)
                Text("Shrinkle").font(Brand.font(96, .heavy)).foregroundStyle(.white)
                Text("Shrink phone photos to 20% in one drop. Free & open source for macOS.")
                    .font(Brand.font(26, .medium)).foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(width: 1280, height: 640)
    }
}
