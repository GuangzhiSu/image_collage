import SwiftUI

struct CropEditor: View {
    @Environment(\.dismiss) private var dismiss
    let photo: CollagePhoto
    let ratio: CGFloat
    let onSave: (PhotoTransform, Int, Bool) -> Void
    @State private var transform: PhotoTransform
    @State private var turns: Int
    @State private var mirrored: Bool
    @State private var displayImage: UIImage
    @State private var dragStart: PhotoTransform?
    @State private var zoomStart: CGFloat?

    init(photo: CollagePhoto, ratio: CGFloat, onSave: @escaping (PhotoTransform, Int, Bool) -> Void) {
        self.photo = photo
        self.ratio = ratio
        self.onSave = onSave
        _transform = State(initialValue: photo.transform)
        _turns = State(initialValue: photo.quarterTurns)
        _mirrored = State(initialValue: photo.mirrored)
        _displayImage = State(initialValue: PhotoStore.oriented(photo.preview, quarterTurns: photo.quarterTurns, mirrored: photo.mirrored))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                GeometryReader { geometry in
                    let fit = CollageGeometry.outputSize(ratio: ratio, longestEdge: max(geometry.size.width, geometry.size.height))
                    let factor = min(geometry.size.width / fit.width, geometry.size.height / fit.height)
                    let size = CGSize(width: fit.width * factor, height: fit.height * factor)
                    CropImage(image: displayImage, transform: transform, size: size)
                        .overlay(Rectangle().stroke(.white.opacity(0.6), lineWidth: 1))
                        .contentShape(Rectangle())
                        .gesture(dragGesture(size: size).simultaneously(with: magnifyGesture))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }.padding(20).background(Color.pintuInk)
                Label("拖动调整位置，双指缩放", systemImage: "hand.draw")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
                HStack(spacing: 14) {
                    Image(systemName: "minus.magnifyingglass")
                    Slider(value: $transform.zoom, in: 1...4).accessibilityLabel("照片缩放")
                    Image(systemName: "plus.magnifyingglass")
                }.padding(.horizontal, 28)
                HStack(spacing: 40) {
                    Button { turns = (turns + 1) % 4; refreshImage() } label: { Label("旋转", systemImage: "rotate.right") }
                    Button { mirrored.toggle(); refreshImage() } label: { Label("镜像", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right") }
                    Button {
                        turns = 0; mirrored = false; refreshImage()
                    } label: { Label("重置", systemImage: "arrow.counterclockwise") }
                }.font(.system(size: 15)).padding(.bottom, 24)
            }
            .navigationTitle("调整照片").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { onSave(transform, turns, mirrored); dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func refreshImage() {
        displayImage = PhotoStore.oriented(photo.preview, quarterTurns: turns, mirrored: mirrored)
        transform = PhotoTransform()
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0).onChanged { value in
            if dragStart == nil { dragStart = transform }
            let initial = dragStart ?? transform
            let frame = CollageGeometry.imageFrame(image: displayImage.size, box: size, transform: transform)
            let overflowX = frame.width - size.width
            let overflowY = frame.height - size.height
            transform.x = overflowX > 0.5 ? min(1, max(-1, initial.x + value.translation.width * 2 / overflowX)) : 0
            transform.y = overflowY > 0.5 ? min(1, max(-1, initial.y + value.translation.height * 2 / overflowY)) : 0
        }.onEnded { _ in dragStart = nil }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture().onChanged { value in
            if zoomStart == nil { zoomStart = transform.zoom }
            transform.zoom = min(4, max(1, (zoomStart ?? 1) * value))
        }.onEnded { _ in zoomStart = nil }
    }
}
