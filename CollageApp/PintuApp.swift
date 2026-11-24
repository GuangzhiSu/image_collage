import SwiftUI

@main
struct PintuApp: App {
    @StateObject private var model = CollageModel()
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(Color.pintuPink)
                .preferredColorScheme(.light)
                .task {
                    if ProcessInfo.processInfo.arguments.contains("--demo") { model.loadDemo() }
                }
        }
    }
}

extension Color {
    static let pintuPink = Color(red: 0.96, green: 0.22, blue: 0.43)
    static let pintuPaper = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let pintuInk = Color(red: 0.11, green: 0.11, blue: 0.13)
}

enum DemoPhotos {
    static func make(_ index: Int) -> UIImage {
        let size = CGSize(width: 900, height: index == 0 ? 720 : 1000)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let palettes: [[UIColor]] = [
                [UIColor(red: 0.97, green: 0.72, blue: 0.59, alpha: 1), UIColor(red: 0.59, green: 0.68, blue: 0.76, alpha: 1)],
                [UIColor(red: 0.77, green: 0.87, blue: 0.84, alpha: 1), UIColor(red: 0.25, green: 0.47, blue: 0.39, alpha: 1)],
                [UIColor(red: 0.76, green: 0.83, blue: 0.94, alpha: 1), UIColor(red: 0.41, green: 0.50, blue: 0.72, alpha: 1)]
            ]
            let cg = context.cgContext
            let colors = palettes[index % 3].map(\.cgColor) as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            UIColor.white.withAlphaComponent(0.6).setFill()
            UIBezierPath(ovalIn: CGRect(x: 570, y: 110, width: 140, height: 140)).fill()
            for layer in 0..<4 {
                let base = size.height * (0.46 + CGFloat(layer) * 0.13)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: -100, y: size.height))
                path.addLine(to: CGPoint(x: -100, y: base + 100))
                path.addCurve(to: CGPoint(x: 1000, y: base + 60), controlPoint1: CGPoint(x: 220, y: base - 300 + CGFloat(index * 50)), controlPoint2: CGPoint(x: 540, y: base + 230))
                path.addLine(to: CGPoint(x: 1000, y: size.height))
                path.close()
                palettes[index % 3][1].withAlphaComponent(0.25 + CGFloat(layer) * 0.17).setFill()
                path.fill()
            }
            let words = ["A little escape.", "Slow mornings.", "Collect moments."]
            words[index % 3].draw(at: CGPoint(x: 48, y: size.height - 100), withAttributes: [
                .font: UIFont.systemFont(ofSize: 42, weight: .medium), .foregroundColor: UIColor.white
            ])
        }
    }
}
