import SwiftUI

private enum EditorPanel: String, CaseIterable { case layouts = "ģ��", border = "�߿�", export = "����" }

struct ContentView: View {
    @ObservedObject var model: CollageModel
    @State private var showPicker = false
    @State private var showReset = false
    @State private var cropPhoto: CollagePhoto?
    @State private var cropRatio: CGFloat = 1
    @State private var panel = EditorPanel.layouts

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                if model.photos.isEmpty { welcome }
                else {
                    preview.frame(height: min(geometry.size.height * 0.43, 390))
                    photoStrip
                    controls
                }
            }
            .background(Color.white)
            .overlay {
                if model.isWorking {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView().tint(.pintuPink).scaleEffect(1.3)
                            Text(model.progressText).font(.subheadline.weight(.medium))
                        }
                        .padding(28).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .accessibilityAddTraits(.isModal)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker(limit: 12 - model.photos.count) { providers in
                showPicker = false
                model.importPhotos(providers)
            }.ignoresSafeArea()
        }
        .sheet(item: $cropPhoto) { photo in
            CropEditor(photo: photo, ratio: cropRatio) { transform, turns, mirrored in
                model.update(photo.id, transform: transform, turns: turns, mirrored: mirrored)
            }
        }
        .sheet(item: $model.shareFile) { file in ShareSheet(url: file.url) }
        .alert(item: $model.notice) { notice in
            if notice.offerSettings {
                return Alert(title: Text(notice.title), message: Text(notice.message),
                             primaryButton: .default(Text("������")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }, secondaryButton: .cancel(Text("�Ժ�")))
            }
            return Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text("�õ�")))
        }
        .confirmationDialog("��յ�ǰƴͼ������ѡ����Ƭ��", isPresented: $showReset, titleVisibility: .visible) {
            Button("���¿�ʼ", role: .destructive) { for photo in model.photos { model.remove(photo.id) } }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if !model.photos.isEmpty {
                Button { showReset = true } label: {
                    Image(systemName: "chevron.left").font(.headline).frame(width: 40, height: 44)
                }.foregroundStyle(Color.pintuInk).accessibilityLabel("���¿�ʼ")
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("ƴͼ").font(.system(size: 25, weight: .bold, design: .rounded))
                Text("PINTU").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(Color.pintuPink)
            }
            Spacer()
            if !model.photos.isEmpty {
                Button { model.export(saveToAlbum: true) } label: {
                    Label("����", systemImage: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold)).padding(.horizontal, 18).padding(.vertical, 11)
                        .background(Color.pintuPink, in: Capsule()).foregroundStyle(.white)
                }.disabled(model.isWorking)
            } else {
                Image(systemName: "sparkle").foregroundStyle(Color.pintuPink).font(.title3)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
    }

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)
            ZStack {
                RoundedRectangle(cornerRadius: 32).fill(Color.pintuPaper).frame(width: 268, height: 290).rotationEffect(.degrees(-7))
                HStack(spacing: 5) {
                    VStack(spacing: 5) {
                        welcomeTile("sun.max", color: Color(red: 0.89, green: 0.57, blue: 0.45))
                        welcomeTile("leaf", color: Color(red: 0.44, green: 0.62, blue: 0.52))
                    }
                    welcomeTile("mountain.2", color: Color(red: 0.45, green: 0.56, blue: 0.71))
                }.padding(9).frame(width: 228, height: 260).background(.white).clipShape(RoundedRectangle(cornerRadius: 24))
                    .rotationEffect(.degrees(5)).shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(Color.pintuPink).offset(x: 128, y: -126)
            }.padding(.bottom, 32)
            Text("��ϲ����˲�䣬\n����һ��").font(.system(size: 31, weight: .bold)).multilineTextAlignment(.center).lineSpacing(6)
            Text("ѡ����Ƭ��ʣ�µĽ������֡�")
                .font(.system(size: 16)).foregroundStyle(.secondary).padding(.top, 14)
            Spacer(minLength: 24)
            Button { showPicker = true } label: {
                Label("�����ѡ����Ƭ", systemImage: "plus")
                    .font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 19)
                    .background(Color.pintuPink, in: RoundedRectangle(cornerRadius: 19)).foregroundStyle(.white)
            }.padding(.horizontal, 28)
            Button("����ʾ����һ��") { model.loadDemo() }.font(.system(size: 15)).foregroundStyle(Color.pintuInk).padding(18)
            Label("1�C12 �� �� ���ش��� �� ��ˮӡ", systemImage: "lock.shield")
                .font(.system(size: 12)).foregroundStyle(.secondary).padding(.bottom, 16)
        }
    }

    private func welcomeTile(_ symbol: String, color: Color) -> some View {
        ZStack {
            LinearGradient(colors: [color.opacity(0.55), color], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: symbol).font(.system(size: 34, weight: .ultraLight)).foregroundStyle(.white.opacity(0.85))
        }.clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var preview: some View {
        GeometryReader { geometry in
            let available = CGSize(width: geometry.size.width - 36, height: geometry.size.height - 44)
            let fit = CollageGeometry.outputSize(ratio: model.composition.ratio,
                                                longestEdge: max(available.width, available.height))
            let scale = min(available.width / fit.width, available.height / fit.height)
            let size = CGSize(width: fit.width * scale, height: fit.height * scale)
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                CollageCanvas(photos: model.photos, cells: model.composition.cells, size: size, gap: model.gap,
                              corner: model.corner, background: Color(CollageModel.colors[model.backgroundIndex])) { index in
                    let frames = CollageGeometry.frames(model.composition.cells, size: size, gap: model.gap)
                    cropRatio = frames[index].width / frames[index].height
                    cropPhoto = model.photos[index]
                }
                Spacer(minLength: 0)
                HStack(spacing: 5) {
                    Image(systemName: "hand.tap")
                    Text("�����Ƭ�����ü�")
                    Text("��  \(model.photos.count) ��").foregroundStyle(.white.opacity(0.45))
                }.font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 10)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.08))
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(model.photos.enumerated()), id: \.element.id) { index, photo in
                    Button {
                        let frames = CollageGeometry.frames(model.composition.cells, size: model.snapshot.size, gap: model.gap)
                        cropRatio = frames[index].width / frames[index].height
                        cropPhoto = photo
                    } label: {
                        Image(uiImage: photo.preview).resizable().scaledToFill().frame(width: 54, height: 54).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .bottomLeading) {
                                Text("\(index + 1)").font(.system(size: 11, weight: .bold)).padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4)).foregroundStyle(.white).padding(3)
                            }
                    }
                    .contextMenu {
                        Button("��ǰ�ƶ�", systemImage: "backward.end") { model.move(photo.id, by: -1) }.disabled(index == 0)
                        Button("����ƶ�", systemImage: "forward.end") { model.move(photo.id, by: 1) }.disabled(index == model.photos.count - 1)
                        Button("�Ƴ���Ƭ", systemImage: "trash", role: .destructive) { model.remove(photo.id) }
                    }
                    .accessibilityLabel("�� \(index + 1) ����Ƭ��������������Ƴ�")
                }
                if model.photos.count < 12 {
                    Button { showPicker = true } label: {
                        Image(systemName: "plus").font(.title3).frame(width: 54, height: 54)
                            .background(Color.pintuPaper, in: RoundedRectangle(cornerRadius: 10))
                    }.accessibilityLabel("������Ƭ")
                }
            }.padding(.horizontal, 20).padding(.vertical, 12)
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            HStack(spacing: 28) {
                ForEach(EditorPanel.allCases, id: \.self) { item in
                    Button { panel = item } label: {
                        VStack(spacing: 8) {
                            Text(item.rawValue).font(.system(size: 16, weight: panel == item ? .semibold : .regular))
                                .foregroundStyle(panel == item ? Color.pintuInk : .secondary)
                            Capsule().fill(panel == item ? Color.pintuPink : .clear).frame(width: 22, height: 3)
                        }
                    }.accessibilityAddTraits(panel == item ? [.isSelected] : [])
                }
                Spacer()
            }.padding(.horizontal, 22).padding(.top, 4)
            Divider().padding(.top, 5)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch panel {
                    case .layouts: layoutControls
                    case .border: borderControls
                    case .export: exportControls
                    }
                }.padding(20)
            }
        }
    }

    private var layoutControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("ƴͼ��ʽ", selection: $model.mode) {
                ForEach(CollageMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }.pickerStyle(.segmented)
            if model.mode == .templates {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CanvasRatio.allCases) { ratio in
                            Button { model.ratio = ratio } label: {
                                Text(ratio.rawValue).font(.system(size: 14, weight: .medium)).padding(.horizontal, 15).padding(.vertical, 9)
                                    .background(model.ratio == ratio ? Color.pintuInk : Color.pintuPaper, in: Capsule())
                                    .foregroundStyle(model.ratio == ratio ? .white : Color.pintuInk)
                            }.accessibilityLabel("�������� \(ratio.rawValue)")
                                .accessibilityAddTraits(model.ratio == ratio ? [.isSelected] : [])
                        }
                    }
                }
                HStack {
                    Text("�ʺ� \(model.photos.count) �ŵĲ���").font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("\(model.layouts.count) ��").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 18) {
                    ForEach(model.layouts) { layout in
                        Button { model.layoutID = layout.id } label: {
                            LayoutTile(layout: layout, selected: model.layout?.id == layout.id)
                        }.buttonStyle(.plain).accessibilityLabel(layout.name)
                            .accessibilityAddTraits(model.layout?.id == layout.id ? [.isSelected] : [])
                    }
                }
            } else {
                Label("������Ƭԭʼ����ƴ�ӣ������������档", systemImage: "rectangle.on.rectangle")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
                Text("�����Ϸ�����ͼ�ɵ���˳������ͼ���Խ�һ���ü���")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
            }
        }
    }

    private var borderControls: some View {
        VStack(alignment: .leading, spacing: 22) {
            settingSlider("��Ƭ���", value: $model.gap, range: 0...0.035)
            settingSlider("��ƬԲ��", value: $model.corner, range: 0...0.06)
            Text("������ɫ").font(.system(size: 15, weight: .medium))
            HStack(spacing: 16) {
                ForEach(CollageModel.colors.indices, id: \.self) { index in
                    Button { model.backgroundIndex = index } label: {
                        Circle().fill(Color(CollageModel.colors[index])).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 1))
                            .padding(4).overlay(Circle().stroke(model.backgroundIndex == index ? Color.pintuPink : .clear, lineWidth: 2))
                    }.accessibilityLabel(CollageModel.colorNames[index])
                }
            }
            Button("�ָ�Ĭ�ϱ߿�") { model.gap = 0.008; model.corner = 0; model.backgroundIndex = 0 }
                .font(.system(size: 14))
        }
    }

    private func settingSlider(_ title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.system(size: 15, weight: .medium))
                Spacer()
                Text("\(Int((value.wrappedValue / range.upperBound * 100).rounded()))%")
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }

    private var exportControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("�����ߴ�").font(.system(size: 16, weight: .semibold))
            Picker("�������", selection: $model.longestEdge) {
                Text("2048 px").tag(CGFloat(2048))
                Text("3072 px").tag(CGFloat(3072))
                Text("4096 px").tag(CGFloat(4096))
            }.pickerStyle(.segmented)
            Text("\(Int(model.snapshot.size.width)) �� \(Int(model.snapshot.size.height)) ���� �� JPEG �� ��ˮӡ")
                .font(.system(size: 14)).foregroundStyle(.secondary)
            Button { model.export(saveToAlbum: true) } label: {
                Label("���浽���", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity).padding(15)
                    .background(Color.pintuPink, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
            }
            Button { model.export(saveToAlbum: false) } label: {
                Label("���� / �洢���ļ�", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).padding(15)
                    .background(Color.pintuPaper, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(Color.pintuInk)
            }
            Text("ԭͼ���ᱻ�޸ġ�����ƴ�ӺͲü�������� iPhone ����ɡ�")
                .font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }
}

struct CollageCanvas: View {
    let photos: [CollagePhoto]
    let cells: [CGRect]
    let size: CGSize
    let gap: CGFloat
    let corner: CGFloat
    let background: Color
    let onTap: (Int) -> Void
    var body: some View {
        let frames = CollageGeometry.frames(cells, size: size, gap: gap)
        ZStack(alignment: .topLeading) {
            background
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                if index < frames.count {
                    let frame = frames[index]
                    let image = PhotoStore.oriented(photo.preview, quarterTurns: photo.quarterTurns, mirrored: photo.mirrored)
                    CropImage(image: image, transform: photo.transform, size: frame.size)
                        .clipShape(RoundedRectangle(cornerRadius: min(size.width, size.height) * corner))
                        .contentShape(Rectangle()).onTapGesture { onTap(index) }
                        .accessibilityLabel("�༭�� \(index + 1) ����Ƭ").accessibilityAddTraits(.isButton)
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }.frame(width: size.width, height: size.height).clipped()
    }
}

struct CropImage: View {
    let image: UIImage
    let transform: PhotoTransform
    let size: CGSize
    var body: some View {
        let rect = CollageGeometry.imageFrame(image: image.size, box: size, transform: transform)
        Image(uiImage: image).resizable().frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .frame(width: size.width, height: size.height, alignment: .topLeading).clipped()
    }
}

private struct LayoutTile: View {
    let layout: CollageLayout
    let selected: Bool
    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { geometry in
                let inset: CGFloat = 7
                let available = CGSize(width: geometry.size.width - 2 * inset, height: geometry.size.height - 2 * inset)
                ZStack(alignment: .topLeading) {
                    ForEach(layout.cells.indices, id: \.self) { index in
                        let rect = layout.cells[index]
                        RoundedRectangle(cornerRadius: 2)
                            .fill(selected ? Color.pintuPink.opacity(0.14) : Color.gray.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(selected ? Color.pintuPink : Color.gray.opacity(0.4), lineWidth: 1.5))
                            .frame(width: max(1, rect.width * available.width - 3), height: max(1, rect.height * available.height - 3))
                            .offset(x: inset + rect.minX * available.width, y: inset + rect.minY * available.height)
                    }
                }
            }.frame(height: 76).background(selected ? Color.pintuPink.opacity(0.04) : Color.pintuPaper, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.pintuPink : .clear, lineWidth: 1.5))
            Text(layout.name).font(.system(size: 11)).foregroundStyle(selected ? Color.pintuPink : .secondary).lineLimit(1)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
