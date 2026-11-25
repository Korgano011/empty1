import SwiftUI
import UniformTypeIdentifiers
import ImageIO

/// A before-and-after photo laid out for saving: both pictures side by side with a caption underneath.
struct BeforeAfterCard: View {
    let spec: PersonSpec
    let date: Date

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                Portrait(spec: spec, after: false, width: 300, height: 480)
                Image(systemName: "arrow.right").font(.system(size: 34, weight: .bold)).foregroundStyle(.secondary)
                Portrait(spec: spec, after: true, width: 300, height: 480)
            }
            Text(spec.name).font(.system(size: 30, weight: .heavy, design: .rounded))
            Text("\(spec.kind.name) alien clown · \(date.formatted(date: .long, time: .shortened))")
                .font(.system(size: 18, design: .rounded)).foregroundStyle(.secondary)
        }
        .padding(28)
        .background(Color(white: 0.97))
        .environment(\.colorScheme, .light)
    }
}

/// One before-and-after photo as a PNG file, ready to save to the computer.
struct PhotoFile: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    var data: Data
    var name: String

    init(data: Data, name: String) {
        self.data = data
        self.name = name
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        name = configuration.file.preferredFilename ?? "Photo"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let w = FileWrapper(regularFileWithContents: data)
        w.preferredFilename = name + ".png"
        return w
    }

    /// Draws the photo with the same code as the album and encodes it as a PNG.
    @MainActor
    static func make(_ spec: PersonSpec, date: Date, suffix: String = "") -> PhotoFile? {
        let renderer = ImageRenderer(content: BeforeAfterCard(spec: spec, date: date))
        renderer.scale = 2
        guard let image = renderer.cgImage else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return PhotoFile(data: out as Data, name: fileName(spec, date: date) + suffix)
    }

    static func fileName(_ spec: PersonSpec, date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let name = "\(spec.name) \(spec.kind.name) Before & After \(f.string(from: date))"
        return name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: ".")
    }
}

/// A button that saves one before-and-after photo to the computer as a PNG.
struct SavePhotoButton: View {
    let spec: PersonSpec
    let date: Date
    /// Icon only, for list rows and cards.
    var compact = false
    @State private var file: PhotoFile?
    @State private var exporting = false

    var body: some View {
        Group {
            if compact {
                Button { save() } label: { Image(systemName: "square.and.arrow.down") }
                    .buttonStyle(.borderless)
            } else {
                Button("Save to Computer…", systemImage: "square.and.arrow.down") { save() }
                    .buttonStyle(.bordered)
            }
        }
        .help("Save this before-and-after photo to your computer")
        .fileExporter(isPresented: $exporting, document: file, contentType: .png,
                      defaultFilename: file?.name ?? PhotoFile.fileName(spec, date: date)) { _ in file = nil }
    }

    private func save() {
        file = PhotoFile.make(spec, date: date)
        exporting = file != nil
    }
}
