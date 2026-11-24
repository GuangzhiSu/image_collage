import SwiftUI
import PhotosUI
import ImageIO
import UniformTypeIdentifiers

struct CollagePhoto: Identifiable {
    let id = UUID()
    let fileURL: URL
    let preview: UIImage
    var transform = PhotoTransform()
    var quarterTurns = 0
    var mirrored = false
    var aspect: CGFloat {
        quarterTurns % 2 == 0 ? preview.size.width / preview.size.height : preview.size.height / preview.size.width
    }
}

enum PhotoStore {
    static func load(provider: NSItemProvider, directory: URL) async throws -> CollagePhoto {
        let url: URL = try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                do {
                    if let error { throw error }
                    guard let url else { throw CocoaError(.fileReadCorruptFile) }
                    let destination = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                    // Provider temporary URLs expire when this callback returns.
                    try FileManager.default.copyItem(at: url, to: destination)
                    continuation.resume(returning: destination)
                } catch { continuation.resume(throwing: error) }
            }
        }
        do {
            let preview = try thumbnail(url: url, maxPixel: 1000)
            return CollagePhoto(fileURL: url, preview: preview)
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    static func thumbnail(url: URL, maxPixel: Int) throws -> UIImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw CocoaError(.fileReadCorruptFile) }
        return UIImage(cgImage: image)
    }

    static func oriented(_ image: UIImage, quarterTurns: Int, mirrored: Bool) -> UIImage {
        guard quarterTurns != 0 || mirrored else { return image }
        let odd = quarterTurns % 2 != 0
        let size = odd ? CGSize(width: image.size.height, height: image.size.width) : image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            cg.translateBy(x: size.width / 2, y: size.height / 2)
            cg.rotate(by: CGFloat(quarterTurns) * .pi / 2)
            if mirrored { cg.scaleBy(x: -1, y: 1) }
            image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2,
                                  width: image.size.width, height: image.size.height))
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    let limit: Int
    let onSelection: ([NSItemProvider]) -> Void
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = max(1, limit)
        configuration.selection = .ordered
        configuration.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onSelection: onSelection) }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelection: ([NSItemProvider]) -> Void
        init(onSelection: @escaping ([NSItemProvider]) -> Void) { self.onSelection = onSelection }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            onSelection(results.map(\.itemProvider))
        }
    }
}
