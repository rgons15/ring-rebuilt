import SwiftUI

extension Color {
    static let ringBlue = Color(red: 0.04, green: 0.48, blue: 0.78)
    static let ringBackground = Color(uiColor: .systemGroupedBackground)
    static let ringInk = Color(uiColor: .label)
}

struct RingCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.04)))
    }
}
extension View { func ringCard() -> some View { modifier(RingCard()) } }

@MainActor struct DemoBadge: View {
    var body: some View {
        Label("DEMO", systemImage: "circle.dotted").font(.caption2.bold())
            .padding(.horizontal, 9).padding(.vertical, 5)
            .foregroundStyle(Color.ringBlue).background(Color.ringBlue.opacity(0.1), in: Capsule())
    }
}

@MainActor struct PorchIllustration: View {
    var night = false
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                LinearGradient(colors: night ? [Color(red: 0.12, green: 0.2, blue: 0.3), .gray] : [Color(red: 0.65, green: 0.81, blue: 0.86), Color(red: 0.89, green: 0.91, blue: 0.82)], startPoint: .top, endPoint: .bottom)
                Rectangle().fill(Color(red: 0.77, green: 0.74, blue: 0.66)).frame(width: w * 0.78, height: h * 0.88).position(x: w * 0.57, y: h * 0.52)
                Path { p in p.move(to: CGPoint(x: w * 0.07, y: h * 0.22)); p.addLine(to: CGPoint(x: w * 0.56, y: -h * 0.18)); p.addLine(to: CGPoint(x: w * 1.1, y: h * 0.22)); p.closeSubpath() }.fill(Color(red: 0.25, green: 0.3, blue: 0.32))
                Rectangle().fill(Color(red: 0.24, green: 0.34, blue: 0.34)).frame(width: w * 0.21, height: h * 0.65).position(x: w * 0.57, y: h * 0.58)
                RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.66, green: 0.81, blue: 0.85)).frame(width: w * 0.16, height: h * 0.3).overlay(Rectangle().stroke(.white.opacity(0.8), lineWidth: 4)).position(x: w * 0.31, y: h * 0.44)
                Circle().fill(.yellow.opacity(0.85)).frame(width: 5).position(x: w * 0.64, y: h * 0.61)
                Path { p in p.move(to: CGPoint(x: w * 0.43, y: h)); p.addLine(to: CGPoint(x: w * 0.49, y: h * 0.83)); p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.83)); p.addLine(to: CGPoint(x: w * 0.91, y: h)); p.closeSubpath() }.fill(Color(red: 0.65, green: 0.65, blue: 0.59))
                ForEach(0..<3) { i in
                    Ellipse().fill(Color(red: 0.23, green: 0.41, blue: 0.26)).frame(width: w * 0.2, height: h * 0.25).position(x: w * (0.1 + Double(i) * 0.075), y: h * 0.86)
                }
                VStack { HStack { Label("DEMO PREVIEW", systemImage: "video.fill").font(.system(size: 9, weight: .semibold)); Spacer() }; Spacer() }.padding(12).foregroundStyle(.white).shadow(radius: 2)
            }
        }.clipped().accessibilityLabel("Illustrated demo porch, not a camera feed")
    }
}
