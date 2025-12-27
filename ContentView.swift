import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isTargeted = false
    @State private var statusMessage = "Drop a PNG file here to convert to JPEG"

    var body: some View {
        VStack {
            Text(statusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            Rectangle()
                .fill(isTargeted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))
                .frame(width: 300, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    return handleDrop(providers: providers)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
            DispatchQueue.main.async {
                guard let urlData = urlData as? Data,
                      let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                    self.statusMessage = "Error: Invalid file"
                    return
                }

                self.convertPNGToJPEG(at: url)
            }
        }

        return true
    }

    private func convertPNGToJPEG(at inputURL: URL) {
        guard inputURL.pathExtension.lowercased() == "png" else {
            statusMessage = "Error: Only PNG files are supported"
            return
        }

        let outputURL = inputURL.deletingPathExtension().appendingPathExtension("jpg")

        guard let nsImage = NSImage(contentsOf: inputURL),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            statusMessage = "Error: Failed to load image"
            return
        }

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            statusMessage = "Error: Failed to create output file"
            return
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.95
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        if CGImageDestinationFinalize(destination) {
            statusMessage = "Conversion successful! JPEG saved as \(outputURL.lastPathComponent)"
        } else {
            statusMessage = "Error: Failed to save JPEG"
        }
    }
}
