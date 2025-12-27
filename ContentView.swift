import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isTargeted = false
    @State private var statusMessage = "Ready to convert PNG files"
    @State private var outputDirectory: URL?
    @State private var selectedFiles: [URL] = []
    @State private var isConverting = false
    @State private var progress: Double = 0.0
    @State private var showConfirmation = false
    @State private var pendingFiles: [URL] = []
    @State private var outputDirString = ""

    var body: some View {
        VStack(spacing: 20) {
            // Output Directory Section
            HStack {
                Text("Output Directory:")
                TextField("Select output directory", text: $outputDirString)
                    .disabled(true)
                    .frame(maxWidth: .infinity)
                Button("Choose...") {
                    selectOutputDirectory()
                }
            }
            .padding(.horizontal)

            // File Selection Buttons
            HStack {
                Button("Select Files") {
                    selectFiles()
                }
                Button("Select Folder") {
                    selectFolder()
                }
            }

            // Drop Zone
            ZStack {
                Rectangle()
                    .fill(isTargeted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        return handleDrop(providers: providers)
                    }

                VStack {
                    Text("Drop PNG files or folders here")
                        .font(.title)
                    Text("or use the buttons above")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Status and Progress
            if isConverting {
                ProgressView(value: progress, total: 1.0)
                    .frame(maxWidth: .infinity)
            }

            Text(statusMessage)
                .multilineTextAlignment(.center)
                .padding()

            // Convert Button
            if !selectedFiles.isEmpty && !isConverting {
                Button("Convert \(selectedFiles.count) file\(selectedFiles.count == 1 ? "" : "s")") {
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .confirmationDialog("Convert Files?", isPresented: $showConfirmation) {
            Button("Convert", role: .destructive) {
                startConversion()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Convert \(selectedFiles.count) PNG file\(selectedFiles.count == 1 ? "" : "s") to JPEG?")
        }
    }

    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url
            outputDirString = url.path
        }
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [UTType.png]
        if panel.runModal() == .OK {
            let urls = panel.urls
            processSelectedURLs(urls)
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            processSelectedURLs([url])
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                if let urlData = urlData as? Data,
                   let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                    urls.append(url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.processSelectedURLs(urls)
        }

        return true
    }

    private func processSelectedURLs(_ urls: [URL]) {
        var pngFiles: [URL] = []

        for url in urls {
            if url.hasDirectoryPath {
                // It's a directory, find all PNGs recursively
                pngFiles.append(contentsOf: findPNGs(in: url))
            } else if url.pathExtension.lowercased() == "png" {
                pngFiles.append(url)
            }
        }

        // Limit to 500 files
        if pngFiles.count > 500 {
            statusMessage = "Error: Too many files selected (\(pngFiles.count)). Maximum is 500."
            return
        }

        selectedFiles = pngFiles
        statusMessage = "\(pngFiles.count) PNG file\(pngFiles.count == 1 ? "" : "s") selected for conversion."
    }

    private func findPNGs(in directory: URL) -> [URL] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        var pngFiles: [URL] = []

        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == "png" {
                pngFiles.append(url)
            }
        }

        return pngFiles
    }

    private func startConversion() {
        guard !selectedFiles.isEmpty else { return }

        isConverting = true
        progress = 0.0
        statusMessage = "Converting files..."

        Task {
            await convertFiles()
        }
    }

    private func convertFiles() async {
        let totalFiles = selectedFiles.count
        var successCount = 0
        var errorCount = 0

        for (index, inputURL) in selectedFiles.enumerated() {
            let outputURL = createOutputURL(for: inputURL)

            if await convertSingleFile(from: inputURL, to: outputURL) {
                successCount += 1
            } else {
                errorCount += 1
            }

            progress = Double(index + 1) / Double(totalFiles)
            await MainActor.run {
                statusMessage = "Converting... \(index + 1)/\(totalFiles)"
            }
        }

        await MainActor.run {
            isConverting = false
            progress = 0.0
            selectedFiles.removeAll()
            statusMessage = "Conversion complete! \(successCount) successful, \(errorCount) failed."
        }
    }

    private func createOutputURL(for inputURL: URL) -> URL {
        let outputDir = outputDirectory ?? inputURL.deletingLastPathComponent()
        let filename = inputURL.deletingPathExtension().lastPathComponent + ".jpg"
        return outputDir.appendingPathComponent(filename)
    }

    private func convertSingleFile(from inputURL: URL, to outputURL: URL) async -> Bool {
        guard let nsImage = NSImage(contentsOf: inputURL),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            return false
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.95
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
}
