import XCTest
import UIKit
@testable import Pintu

final class CollageTests: XCTestCase {
    func testEveryLayoutTilesTheCanvasExactlyForOneThroughTwelvePhotos() {
        for count in 1...12 {
            let layouts = CollageGeometry.layouts(for: count)
            XCTAssertFalse(layouts.isEmpty)
            XCTAssertEqual(Set(layouts.map(\.id)).count, layouts.count)
            for layout in layouts {
                XCTAssertEqual(layout.cells.count, count, layout.id)
                XCTAssertEqual(layout.cells.reduce(CGFloat(0)) { $0 + $1.width * $1.height }, 1, accuracy: 0.00001)
                for (index, cell) in layout.cells.enumerated() {
                    XCTAssertGreaterThan(cell.width, 0)
                    XCTAssertGreaterThan(cell.height, 0)
                    XCTAssertGreaterThanOrEqual(cell.minX, -0.00001)
                    XCTAssertGreaterThanOrEqual(cell.minY, -0.00001)
                    XCTAssertLessThanOrEqual(cell.maxX, 1.00001)
                    XCTAssertLessThanOrEqual(cell.maxY, 1.00001)
                    for other in layout.cells.dropFirst(index + 1) {
                        let intersection = cell.intersection(other)
                        XCTAssertTrue(intersection.isNull || intersection.width * intersection.height < 0.00001, layout.id)
                    }
                }
            }
        }
        XCTAssertTrue(CollageGeometry.layouts(for: 0).isEmpty)
        XCTAssertTrue(CollageGeometry.layouts(for: 13).isEmpty)
    }

    func testCropNeverExposesBlankCanvas() {
        for image in [CGSize(width: 400, height: 200), CGSize(width: 100, height: 900)] {
            for box in [CGSize(width: 800, height: 200), CGSize(width: 100, height: 600)] {
                for zoom: CGFloat in [1, 2, 4] {
                    for x: CGFloat in [-1, 0, 1] {
                        for y: CGFloat in [-1, 0, 1] {
                            let rect = CollageGeometry.imageFrame(image: image, box: box, transform: PhotoTransform(zoom: zoom, x: x, y: y))
                            XCTAssertLessThanOrEqual(rect.minX, 0.0001)
                            XCTAssertLessThanOrEqual(rect.minY, 0.0001)
                            XCTAssertGreaterThanOrEqual(rect.maxX, box.width - 0.0001)
                            XCTAssertGreaterThanOrEqual(rect.maxY, box.height - 0.0001)
                        }
                    }
                }
            }
        }
    }

    func testStripKeepsOriginalAspects() {
        let aspects: [CGFloat] = [0.5, 2, 1.5]
        for vertical in [true, false] {
            let strip = CollageGeometry.strip(aspects: aspects, vertical: vertical)
            for (index, cell) in strip.cells.enumerated() {
                XCTAssertEqual(cell.width / cell.height * strip.ratio, aspects[index], accuracy: 0.00001)
            }
        }
    }

    func testExtremeStripsAndMaximumGapKeepPositiveFrames() {
        let aspects: [CGFloat] = [0.01, 100, 1]
        for vertical in [true, false] {
            let strip = CollageGeometry.strip(aspects: aspects, vertical: vertical)
            let size = CollageGeometry.outputSize(ratio: strip.ratio, longestEdge: 4096)
            let frames = CollageGeometry.frames(strip.cells, size: size, gap: 0.035)
            XCTAssertTrue(frames.allSatisfy { $0.width > 0 && $0.height > 0 })
        }
    }

    func testRendererCreatesExpectedPixelsAndDimensions() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let photos = try [UIColor.red, .blue].enumerated().map { index, color -> CollagePhoto in
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100), format: format).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            }
            let url = directory.appendingPathComponent("\(index).png")
            try XCTUnwrap(image.pngData()).write(to: url)
            return CollagePhoto(fileURL: url, preview: image)
        }
        let snapshot = CollageSnapshot(photos: photos, cells: CollageGeometry.rows([1, 1]), ratio: 1,
                                       gap: 0, corner: 0, background: .white, longestEdge: 400)
        let rendered = try CollageRenderer.render(snapshot)
        XCTAssertEqual(rendered.cgImage?.width, 400)
        XCTAssertEqual(rendered.cgImage?.height, 400)
        let top = try pixel(rendered, x: 200, y: 50)
        let bottom = try pixel(rendered, x: 200, y: 350)
        XCTAssertGreaterThan(top.0, 240)
        XCTAssertLessThan(top.2, 15)
        XCTAssertGreaterThan(bottom.2, 240)
        XCTAssertLessThan(bottom.0, 15)
        let rotated = PhotoStore.oriented(photos[0].preview, quarterTurns: 1, mirrored: true)
        XCTAssertEqual(rotated.size.width, 100)
    }

    private func pixel(_ image: UIImage, x: Int, y: Int) throws -> (UInt8, UInt8, UInt8) {
        let source = try XCTUnwrap(image.cgImage)
        var bytes = [UInt8](repeating: 0, count: source.width * source.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: source.width, height: source.height,
            bitsPerComponent: 8, bytesPerRow: source.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(source, in: CGRect(x: 0, y: 0, width: source.width, height: source.height))
        let offset = (y * source.width + x) * 4
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2])
    }
}
