import Foundation

enum CanvasRatio: String, CaseIterable, Identifiable {
    case portrait = "3:4", square = "1:1", landscape = "4:3"
    case story = "9:16", wide = "16:9", social = "4:5", classic = "2:3"
    var id: String { rawValue }
    var value: CGFloat {
        switch self {
        case .portrait: return 3 / 4
        case .square: return 1
        case .landscape: return 4 / 3
        case .story: return 9 / 16
        case .wide: return 16 / 9
        case .social: return 4 / 5
        case .classic: return 2 / 3
        }
    }
}

enum CollageMode: String, CaseIterable, Identifiable {
    case templates = "ģ��", vertical = "����ͼ", horizontal = "����ƴ��"
    var id: String { rawValue }
}

struct CollageLayout: Identifiable {
    let id: String
    let name: String
    let cells: [CGRect]
}

struct PhotoTransform: Equatable {
    var zoom: CGFloat = 1
    // Position is normalized to available crop overflow, so it survives template changes.
    var x: CGFloat = 0
    var y: CGFloat = 0
}

enum CollageGeometry {
    static func rows(_ counts: [Int], weights: [CGFloat]? = nil) -> [CGRect] {
        let heights = weights ?? Array(repeating: 1, count: counts.count)
        let total = heights.reduce(0, +)
        var y: CGFloat = 0
        var cells: [CGRect] = []
        for (row, count) in counts.enumerated() {
            let height = heights[row] / total
            for column in 0..<count {
                cells.append(CGRect(x: CGFloat(column) / CGFloat(count), y: y,
                                    width: 1 / CGFloat(count), height: height))
            }
            y += height
        }
        return cells
    }

    static func transpose(_ cells: [CGRect]) -> [CGRect] {
        cells.map { CGRect(x: $0.minY, y: $0.minX, width: $0.height, height: $0.width) }
    }

    static func layouts(for count: Int) -> [CollageLayout] {
        guard (1...12).contains(count) else { return [] }
        if count == 1 { return [CollageLayout(id: "single", name: "���Ż���", cells: rows([1]))] }
        var result: [CollageLayout] = []
        func add(_ id: String, _ name: String, _ cells: [CGRect]) {
            // Deduplicate visually identical layouts.
            let signature = cells.map { [$0.minX, $0.minY, $0.width, $0.height].map { Int(($0 * 10000).rounded()) } }
            guard !result.contains(where: { layout in
                layout.cells.map { [$0.minX, $0.minY, $0.width, $0.height].map { Int(($0 * 10000).rounded()) } } == signature
            }) else { return }
            result.append(CollageLayout(id: id, name: name, cells: cells))
        }
        if count >= 3 {
            let remainingRows = balancedCounts(count - 1, columns: count > 7 ? 3 : 2)
            let bottom = rows(remainingRows).map {
                CGRect(x: $0.minX, y: 0.6 + $0.minY * 0.4, width: $0.width, height: $0.height * 0.4)
            }
            let hero = [CGRect(x: 0, y: 0, width: 1, height: 0.6)] + bottom
            add("hero-top", "�ϴ���С", hero)
            add("hero-left", "�����С", transpose(hero))
            add("hero-bottom", "�·���ͼ", hero.map { CGRect(x: $0.minX, y: 1 - $0.maxY, width: $0.width, height: $0.height) })
            add("hero-right", "�Ҳ���ͼ", transpose(hero).map { CGRect(x: 1 - $0.maxX, y: $0.minY, width: $0.width, height: $0.height) })
        }
        for columns in 1...min(count, 4) {
            let counts = balancedCounts(count, columns: columns)
            let grid = rows(counts)
            add("grid-\(columns)", columns == 1 ? "��������" : "\(columns) ������", grid)
            add("columns-\(columns)", columns == 1 ? "��������" : "\(columns) ������", transpose(grid))
            if counts.count > 1 && counts.first != counts.last {
                add("reverse-\(columns)", "��������", rows(Array(counts.reversed())))
            }
        }
        if count >= 3 && count <= 6 {
            for split in 1..<count {
                add("split-\(split)", "���·���", rows([split, count - split]))
                add("split-t-\(split)", "���ҷ���", transpose(rows([split, count - split])))
            }
        }
        return result
    }

    static func balancedCounts(_ count: Int, columns: Int) -> [Int] {
        let rowCount = Int(ceil(Double(count) / Double(columns)))
        return (0..<rowCount).map { min(columns, count - $0 * columns) }
    }

    static func strip(aspects: [CGFloat], vertical: Bool) -> (cells: [CGRect], ratio: CGFloat) {
        guard !aspects.isEmpty else { return ([], 1) }
        let lengths = aspects.map { vertical ? 1 / max($0, 0.01) : max($0, 0.01) }
        let total = lengths.reduce(0, +)
        var start: CGFloat = 0
        let cells = lengths.map { length -> CGRect in
            defer { start += length / total }
            return vertical ? CGRect(x: 0, y: start, width: 1, height: length / total)
                            : CGRect(x: start, y: 0, width: length / total, height: 1)
        }
        return (cells, vertical ? 1 / total : total)
    }

    static func frames(_ cells: [CGRect], size: CGSize, gap: CGFloat) -> [CGRect] {
        let smallestCell = cells.map { min($0.width * size.width, $0.height * size.height) }.min() ?? 1
        // Extreme panoramas or screenshots must not produce negative cell sizes.
        let inset = min(min(size.width, size.height) * gap, smallestCell * 0.4)
        let usable = CGRect(origin: .zero, size: size).insetBy(dx: inset / 2, dy: inset / 2)
        return cells.map {
            CGRect(x: usable.minX + $0.minX * usable.width, y: usable.minY + $0.minY * usable.height,
                   width: $0.width * usable.width, height: $0.height * usable.height)
                .insetBy(dx: inset / 2, dy: inset / 2)
        }
    }

    static func imageFrame(image: CGSize, box: CGSize, transform: PhotoTransform) -> CGRect {
        let scale = max(box.width / max(image.width, 1), box.height / max(image.height, 1)) * transform.zoom
        let size = CGSize(width: image.width * scale, height: image.height * scale)
        return CGRect(x: (box.width - size.width) / 2 + transform.x * (size.width - box.width) / 2,
                      y: (box.height - size.height) / 2 + transform.y * (size.height - box.height) / 2,
                      width: size.width, height: size.height)
    }

    static func outputSize(ratio: CGFloat, longestEdge: CGFloat) -> CGSize {
        let ratio = max(ratio, 0.001)
        return ratio >= 1 ? CGSize(width: longestEdge, height: max(1, (longestEdge / ratio).rounded()))
                          : CGSize(width: max(1, (longestEdge * ratio).rounded()), height: longestEdge)
    }
}
