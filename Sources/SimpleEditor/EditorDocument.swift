import Foundation
import Combine

final class EditorDocument: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var content: String
    @Published var fileURL: URL?
    @Published var isModified: Bool = false

    private var cancellable: AnyCancellable?

    init(title: String = "Untitled", content: String = "", fileURL: URL? = nil) {
        self.title = title
        self.content = content
        self.fileURL = fileURL

        cancellable = $content
            .dropFirst()
            .sink { [weak self] _ in
                self?.isModified = true
            }
    }

    var displayTitle: String {
        let name = fileURL?.lastPathComponent ?? title
        return isModified ? "\(name) *" : name
    }

    func load(from url: URL) throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        self.fileURL = url
        self.title = url.lastPathComponent
        self.content = text
        self.isModified = false
    }

    func save() throws {
        guard let url = fileURL else { return }
        try content.write(to: url, atomically: true, encoding: .utf8)
        isModified = false
    }

    func save(to url: URL) throws {
        self.fileURL = url
        self.title = url.lastPathComponent
        try save()
    }
}
