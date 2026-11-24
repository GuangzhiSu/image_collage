import SwiftUI
import PhotosUI

struct EditorNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    var offerSettings = false
}

struct ShareFile: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
final class CollageModel: ObservableObject {
    @Published var photos: [CollagePhoto] = []
    @Published var ratio = CanvasRatio.portrait
    @Published var mode = CollageMode.templates
    @Published var layoutID = "hero-top"
    @Published var gap: CGFloat = 0.008
    @Published var corner: CGFloat = 0
    @Published var backgroundIndex = 0
    @Published var longestEdge: CGFloat = 4096
    @Published var isWorking = false
    @Published var progressText = ""
    @Published var notice: EditorNotice?
    @Published var shareFile: ShareFile?
    let importDirectory: URL

    static let colors: [UIColor] = [.white, .black, UIColor(red: 1, green: 0.91, blue: 0.94, alpha: 1),
        UIColor(red: 0.87, green: 0.92, blue: 1, alpha: 1), UIColor(red: 0.88, green: 0.95, blue: 0.87, alpha: 1),
        UIColor(red: 1, green: 0.91, blue: 0.68, alpha: 1)]
    static let colorNames = ["��ɫ", "��ɫ", "ǳ��", "ǳ��", "ǳ��", "�̻�"]

    init() {
        importDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Pintu-\(UUID().uuidString)", isDirectory: true)
        do { try FileManager.default.createDirectory(at: importDirectory, withIntermediateDirectories: true) }
        catch { notice = EditorNotice(title: "�洢�ռ䲻����", message: error.localizedDescription) }
    }

    deinit { try? FileManager.default.removeItem(at: importDirectory) }

    var layouts: [CollageLayout] { CollageGeometry.layouts(for: photos.count) }
    var layout: CollageLayout? { layouts.first { $0.id == layoutID } ?? layouts.first }
    var composition: (cells: [CGRect], ratio: CGFloat) {
        switch mode {
        case .templates: return (layout?.cells ?? [], ratio.value)
        case .vertical: return CollageGeometry.strip(aspects: photos.map(\.aspect), vertical: true)
        case .horizontal: return CollageGeometry.strip(aspects: photos.map(\.aspect), vertical: false)
        }
    }
    var snapshot: CollageSnapshot {
        CollageSnapshot(photos: photos, cells: composition.cells, ratio: composition.ratio, gap: gap,
                        corner: corner, background: Self.colors[backgroundIndex], longestEdge: longestEdge)
    }

    func importPhotos(_ providers: [NSItemProvider]) {
        guard !providers.isEmpty, !isWorking else { return }
        isWorking = true
        Task {
            var failed = 0
            let selected = Array(providers.prefix(12 - photos.count))
            for (index, provider) in selected.enumerated() {
                progressText = "���ڶ�ȡ��Ƭ \(index + 1) / \(selected.count)"
                do { photos.append(try await PhotoStore.load(provider: provider, directory: importDirectory)) }
                catch { failed += 1 }
            }
            layoutID = layouts.first?.id ?? "single"
            isWorking = false
            if failed > 0 {
                notice = EditorNotice(title: "�� \(failed) ����Ƭδ�ܶ�ȡ", message: "�ѱ���������Ƭ������ iCloud ���ػ�ͼƬ��ʽ��Ȼ������ѡ��")
            }
        }
    }

    func remove(_ id: UUID) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
        let photo = photos.remove(at: index)
        try? FileManager.default.removeItem(at: photo.fileURL)
        layoutID = layouts.first?.id ?? "single"
    }

    func move(_ id: UUID, by offset: Int) {
        guard let index = photos.firstIndex(where: { $0.id == id }), photos.indices.contains(index + offset) else { return }
        photos.swapAt(index, index + offset)
    }

    func update(_ id: UUID, transform: PhotoTransform, turns: Int, mirrored: Bool) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
        photos[index].transform = transform
        photos[index].quarterTurns = turns
        photos[index].mirrored = mirrored
    }

    func export(saveToAlbum: Bool) {
        guard !photos.isEmpty, !isWorking else { return }
        isWorking = true
        progressText = "�������ɸ���ƴͼ"
        let current = snapshot
        Task {
            do {
                let image = try await Task.detached(priority: .userInitiated) { try CollageRenderer.render(current) }.value
                if saveToAlbum {
                    progressText = "���ڱ��浽���"
                    try await CollageRenderer.saveToPhotos(image)
                    notice = EditorNotice(title: "�ѱ��浽���", message: "\(Int(current.size.width)) �� \(Int(current.size.height)) ���� �� ��ˮӡ")
                } else {
                    let url = importDirectory.appendingPathComponent("Pintu-\(UUID().uuidString.prefix(8)).jpg")
                    guard let data = image.jpegData(compressionQuality: 0.96) else { throw CollageRenderer.ExportError.encodingFailed }
                    try data.write(to: url, options: .atomic)
                    shareFile = ShareFile(url: url)
                }
            } catch {
                let denied = (error as? CollageRenderer.ExportError) == .permissionDenied
                notice = EditorNotice(title: "δ����ɱ���", message: error.localizedDescription, offerSettings: denied)
            }
            isWorking = false
        }
    }

    func loadDemo() {
        guard photos.isEmpty else { return }
        do {
            for index in 0..<3 {
                let url = importDirectory.appendingPathComponent("demo-\(index).jpg")
                let image = DemoPhotos.make(index)
                guard let data = image.jpegData(compressionQuality: 0.95) else { continue }
                try data.write(to: url)
                photos.append(CollagePhoto(fileURL: url, preview: image))
            }
            layoutID = "hero-top"
        } catch { notice = EditorNotice(title: "ʾ����ȡʧ��", message: error.localizedDescription) }
    }
}
