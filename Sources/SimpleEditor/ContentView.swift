import SwiftUI
import AppKit

struct ContentView: View {
    @State private var documents: [EditorDocument] = [EditorDocument()]
    @State private var selectedTabID: UUID?
    @State private var saveDirectory: URL?

    private var selectedDocument: EditorDocument? {
        documents.first { $0.id == selectedTabID }
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            editorArea
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            if selectedTabID == nil {
                selectedTabID = documents.first?.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTab)) { _ in newTab() }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in openFile() }
        .onReceive(NotificationCenter.default.publisher(for: .saveFile)) { _ in saveFile() }
        .onReceive(NotificationCenter.default.publisher(for: .saveAllToDirectory)) { _ in saveAllToDirectory() }
        .onReceive(NotificationCenter.default.publisher(for: .closeTab)) { _ in closeCurrentTab() }
        .onReceive(NotificationCenter.default.publisher(for: .previousTab)) { _ in switchTab(offset: -1) }
        .onReceive(NotificationCenter.default.publisher(for: .nextTab)) { _ in switchTab(offset: 1) }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(documents) { doc in
                    tabItem(for: doc)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 32)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func tabItem(for doc: EditorDocument) -> some View {
        HStack(spacing: 4) {
            Text(doc.displayTitle)
                .font(.system(size: 12))
                .lineLimit(1)

            Button(action: { closeTab(doc) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 14, height: 14)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(selectedTabID == doc.id
                    ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.3)
                    : Color.clear)
        )
        .onTapGesture {
            selectedTabID = doc.id
        }
    }

    // MARK: - Editor Area

    private var editorArea: some View {
        Group {
            if let doc = selectedDocument {
                EditorTextView(document: doc)
            } else {
                Text("No document open")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Actions

    private func newTab() {
        let doc = EditorDocument()
        documents.append(doc)
        selectedTabID = doc.id
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText, .sourceCode, .data]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let doc = EditorDocument()
        do {
            try doc.load(from: url)
            documents.append(doc)
            selectedTabID = doc.id
        } catch {
            showError("Failed to open file: \(error.localizedDescription)")
        }
    }

    private func saveFile() {
        guard let doc = selectedDocument else { return }
        if doc.fileURL != nil {
            do {
                try doc.save()
            } catch {
                showError("Failed to save: \(error.localizedDescription)")
            }
        } else {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = doc.title
            guard panel.runModal() == .OK, let url = panel.url else { return }
            do {
                try doc.save(to: url)
            } catch {
                showError("Failed to save: \(error.localizedDescription)")
            }
        }
    }

    private func saveAllToDirectory() {
        let directory: URL
        if let saved = saveDirectory {
            directory = saved
        } else {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Select"
            panel.message = "Choose a directory to save all tabs"

            guard panel.runModal() == .OK, let url = panel.url else { return }
            saveDirectory = url
            directory = url
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateDir = directory.appendingPathComponent(formatter.string(from: Date()))

        do {
            try FileManager.default.createDirectory(at: dateDir, withIntermediateDirectories: true)
        } catch {
            showError("Failed to create directory: \(error.localizedDescription)")
            return
        }

        for doc in documents {
            let fileName = doc.fileURL?.lastPathComponent ?? doc.title
            let fileURL = dateDir.appendingPathComponent(fileName)
            do {
                try doc.save(to: fileURL)
            } catch {
                showError("Failed to save \(fileName): \(error.localizedDescription)")
            }
        }
    }

    private func closeTab(_ doc: EditorDocument) {
        guard let index = documents.firstIndex(where: { $0.id == doc.id }) else { return }
        let wasSelected = selectedTabID == doc.id
        documents.remove(at: index)

        if wasSelected {
            if documents.isEmpty {
                newTab()
            } else {
                let newIndex = min(index, documents.count - 1)
                selectedTabID = documents[newIndex].id
            }
        }
    }

    private func switchTab(offset: Int) {
        guard documents.count > 1,
              let currentIndex = documents.firstIndex(where: { $0.id == selectedTabID }) else { return }
        let newIndex = (currentIndex + offset + documents.count) % documents.count
        selectedTabID = documents[newIndex].id
    }

    private func closeCurrentTab() {
        guard let doc = selectedDocument else { return }
        closeTab(doc)
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

// MARK: - TextEditor Wrapper

struct EditorTextView: View {
    @ObservedObject var document: EditorDocument

    var body: some View {
        TextEditor(text: $document.content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.visible)
    }
}

