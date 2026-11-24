import UIKit
import Photos

struct CollageSnapshot {
    let photos: [CollagePhoto]
    let cells: [CGRect]
    let ratio: CGFloat
    let gap: CGFloat
    let corner: CGFloat
    let background: UIColor
    let longestEdge: CGFloat
    var size: CGSize { CollageGeometry.outputSize(ratio: ratio, longestEdge: longestEdge) }
}

enum CollageRenderer {
    static func render(_ snapshot: CollageSnapshot) throws -> UIImage {
        guard !snapshot.photos.isEmpty, snapshot.cells.count == snapshot.photos.count else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // Load and draw one full-size source at a time. Never hold 12 full-size originals in RAM.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let frames = CollageGeometry.frames(snapshot.cells, size: snapshot.size, gap: snapshot.gap)
        var readError: Error?
        let result = UIGraphicsImageRenderer(size: snapshot.size, format: format).image { context in
            snapshot.background.setFill()
            context.fill(CGRect(origin: .zero, size: snapshot.size))
            for (index, photo) in snapshot.photos.enumerated() {
                autoreleasepool {
                    do {
                        let source = try PhotoStore.thumbnail(url: photo.fileURL, maxPixel: Int(snapshot.longestEdge))
                        let image = PhotoStore.oriented(source, quarterTurns: photo.quarterTurns, mirrored: photo.mirrored)
                        let cell = frames[index]
                        let imageRect = CollageGeometry.imageFrame(image: image.size, box: cell.size, transform: photo.transform)
                        let cg = context.cgContext
                        cg.saveGState()
                        let radius = min(snapshot.size.width, snapshot.size.height) * snapshot.corner
                        UIBezierPath(roundedRect: cell, cornerRadius: radius).addClip()
                        image.draw(in: imageRect.offsetBy(dx: cell.minX, dy: cell.minY))
                        cg.restoreGState()
                    } catch { readError = error }
                }
            }
        }
        if let readError { throw readError }
        return result
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.permissionDenied }
        guard let data = image.jpegData(compressionQuality: 0.96) else { throw ExportError.encodingFailed }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = "Pintu-\(Int(Date().timeIntervalSince1970)).jpg"
            request.addResource(with: .photo, data: data, options: options)
        }
    }

    enum ExportError: LocalizedError, Equatable {
        case permissionDenied, encodingFailed
        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "需要允许添加照片，才能保存到相册。你也可以通过分享将拼图存储到文件。"
            case .encodingFailed: return "图片生成失败，请重试。"
            }
        }
    }
}
