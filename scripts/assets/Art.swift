import SwiftUI

// Shared artwork for the logo, app icon and README images.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Brand {
    static let orange = Color(hex: 0xFFA24C)
    static let pink = Color(hex: 0xFF4F7B)
    static let violet = Color(hex: 0x8B5CF6)
    static let gradient = LinearGradient(colors: [orange, pink, violet],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Four-point twinkle star
struct Sparkle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let k = 0.12
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: c.x + r.width * k, y: c.y - r.height * k))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: c.x + r.width * k, y: c.y + r.height * k))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: c.x - r.width * k, y: c.y + r.height * k))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: c.x - r.width * k, y: c.y - r.height * k))
        p.closeSubpath()
        return p
    }
}

/// Two diagonal arrows pointing inward: the "shrink" gesture
struct InwardArrows: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * s, y: r.minY + y * s) }
        var p = Path()
        // top-left arrow, pointing down-right
        p.move(to: pt(0.13, 0.13)); p.addLine(to: pt(0.27, 0.27))
        p.move(to: pt(0.165, 0.27)); p.addLine(to: pt(0.27, 0.27)); p.addLine(to: pt(0.27, 0.165))
        // bottom-right arrow, pointing up-left
        p.move(to: pt(0.87, 0.87)); p.addLine(to: pt(0.73, 0.73))
        p.move(to: pt(0.835, 0.73)); p.addLine(to: pt(0.73, 0.73)); p.addLine(to: pt(0.73, 0.835))
        return p
    }
}

struct Mountains: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.32, y: r.minY + r.height * 0.35))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.52, y: r.minY + r.height * 0.62))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.70, y: r.minY + r.height * 0.20))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// The little white photo card in the middle of the logo
struct PhotoCard: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.09, style: .continuous).fill(.white)
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x9FD8FF), Color(hex: 0xFFD6B0)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(hex: 0xFFC83D))
                        .frame(width: w * 0.2, height: w * 0.2)
                        .position(x: w * 0.62, y: g.size.height * 0.3)
                    Mountains().fill(Color(hex: 0xFF6F91))
                        .offset(x: w * 0.12)
                    Mountains().fill(Color(hex: 0x7C4DFF))
                        .scaleEffect(x: 1.1, y: 0.8, anchor: .bottom)
                        .offset(x: -w * 0.18)
                }
                .clipShape(RoundedRectangle(cornerRadius: w * 0.05, style: .continuous))
                .padding(w * 0.07)
            }
        }
    }
}

/// The logo mark itself, filling a square
struct LogoMark: View {
    var body: some View {
        GeometryReader { g in
            let s = g.size.width
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.225, style: .continuous).fill(Brand.gradient)
                RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                    .fill(RadialGradient(colors: [.white.opacity(0.35), .clear],
                                         center: .topLeading, startRadius: 0, endRadius: s * 0.9))
                InwardArrows()
                    .stroke(.white, style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round, lineJoin: .round))
                PhotoCard()
                    .frame(width: s * 0.44, height: s * 0.36)
                    .rotationEffect(.degrees(-6))
                    .shadow(color: .black.opacity(0.25), radius: s * 0.03, y: s * 0.015)
                    .position(x: s * 0.5, y: s * 0.5)
                Sparkle().fill(.white)
                    .frame(width: s * 0.17, height: s * 0.17)
                    .position(x: s * 0.77, y: s * 0.23)
                Sparkle().fill(.white.opacity(0.85))
                    .frame(width: s * 0.08, height: s * 0.08)
                    .position(x: s * 0.89, y: s * 0.37)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// macOS app icon: logo on the standard 1024 grid (824 body + shadow)
struct AppIconView: View {
    var body: some View {
        LogoMark()
            .frame(width: 824, height: 824)
            .shadow(color: .black.opacity(0.28), radius: 14, y: 10)
            .frame(width: 1024, height: 1024)
    }
}

// MARK: - Sample "photos" (stylised, generated, no real photos used)

struct SceneArt: View {
    let kind: Int
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            switch kind % 5 {
            case 0: // sunset over the sea
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x2B1B5A), Color(hex: 0xC2417A), Color(hex: 0xFF9A4D)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.62))
                    Circle().fill(Color(hex: 0xFFE08A)).frame(width: w * 0.22).position(x: w * 0.5, y: h * 0.58)
                    LinearGradient(colors: [Color(hex: 0x3A2470), Color(hex: 0x120C2C)], startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.38).position(x: w / 2, y: h * 0.81)
                    ForEach(0..<6) { i in
                        Capsule().fill(Color(hex: 0xFFC27A, opacity: 0.7 - Double(i) * 0.1))
                            .frame(width: w * (0.18 - CGFloat(i) * 0.02), height: h * 0.012)
                            .position(x: w * 0.5, y: h * (0.66 + CGFloat(i) * 0.045))
                    }
                }
            case 1: // snowy mountains
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x6EC6FF), Color(hex: 0xD8F0FF)], startPoint: .top, endPoint: .bottom)
                    Mountains().fill(Color(hex: 0x5B6B9A)).frame(height: h * 0.7).position(x: w * 0.55, y: h * 0.65)
                    Mountains().fill(Color(hex: 0x3D4B78)).frame(height: h * 0.55).scaleEffect(x: -1).position(x: w * 0.4, y: h * 0.73)
                    Ellipse().fill(Color(hex: 0x3FA66B)).frame(width: w * 1.6, height: h * 0.5).position(x: w * 0.3, y: h * 1.05)
                    Ellipse().fill(Color(hex: 0x2E8A57)).frame(width: w * 1.4, height: h * 0.45).position(x: w * 0.9, y: h * 1.1)
                }
            case 2: // city at night
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x0B1030), Color(hex: 0x2A2F7A)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(hex: 0xFFF3C4)).frame(width: w * 0.08).position(x: w * 0.8, y: h * 0.18)
                    HStack(alignment: .bottom, spacing: w * 0.012) {
                        ForEach(0..<11) { i in
                            let bh = h * [0.42, 0.6, 0.35, 0.72, 0.5, 0.82, 0.45, 0.62, 0.38, 0.55, 0.48][i]
                            ZStack(alignment: .top) {
                                Rectangle().fill(Color(hex: [0x1A1F4D, 0x232A63, 0x161A40][i % 3]))
                                VStack(spacing: h * 0.03) {
                                    ForEach(0..<Int(bh / (h * 0.06)), id: \.self) { j in
                                        HStack(spacing: w * 0.012) {
                                            ForEach(0..<3) { k in
                                                Rectangle().fill((i + j + k) % 3 == 0 ? Color(hex: 0xFFD27A) : Color(hex: 0x3A4288))
                                                    .frame(width: w * 0.012, height: h * 0.022)
                                            }
                                        }
                                    }
                                }.padding(.top, h * 0.03)
                            }
                            .frame(width: w * 0.08, height: bh)
                        }
                    }
                    .frame(width: w, height: h, alignment: .bottom)
                }
            case 3: // desert dunes
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xFFB36B), Color(hex: 0xFFE3B3)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(hex: 0xFFF6D8)).frame(width: w * 0.16).position(x: w * 0.25, y: h * 0.28)
                    Ellipse().fill(Color(hex: 0xE58A3C)).frame(width: w * 1.3, height: h * 0.6).position(x: w * 0.75, y: h * 0.9)
                    Ellipse().fill(Color(hex: 0xC96A2B)).frame(width: w * 1.2, height: h * 0.5).position(x: w * 0.1, y: h * 1.0)
                }
            default: // forest lake
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xA8E6CF), Color(hex: 0xE8F8F0)], startPoint: .top, endPoint: .bottom)
                    HStack(alignment: .bottom, spacing: -w * 0.02) {
                        ForEach(0..<9) { i in
                            Triangle().fill(Color(hex: i % 2 == 0 ? 0x1F7A4D : 0x2E9960))
                                .frame(width: w * 0.14, height: h * [0.38, 0.5, 0.42, 0.56, 0.4, 0.52, 0.44, 0.36, 0.48][i])
                        }
                    }
                    .frame(width: w, height: h * 0.62, alignment: .bottom)
                    .position(x: w / 2, y: h * 0.31)
                    LinearGradient(colors: [Color(hex: 0x3BA7C9), Color(hex: 0x1C6E8C)], startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.38).position(x: w / 2, y: h * 0.81)
                }
            }
        }
        .clipped()
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
