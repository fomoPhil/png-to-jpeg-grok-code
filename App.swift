import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@main
struct PNGToJPEGApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Handle command line arguments for service-like behavior
        let args = CommandLine.arguments
        if args.count > 1 {
            // Remove the first argument (app path)
            let filePaths = Array(args.dropFirst())

            // Process the files
            handleServiceFiles(filePaths)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Set up services provider
        NSApplication.shared.servicesProvider = self
    }

    // Service method called by Finder contextual menu
    @objc func convertFiles(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        // Get the file URLs from the pasteboard
        guard let fileURLs = pboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? [String] else {
            error.pointee = "Could not get file URLs from pasteboard" as NSString
            return
        }

        // Convert strings to URLs and filter for PNG files
        let pngURLs = fileURLs.compactMap { URL(fileURLWithPath: $0) }.filter { $0.pathExtension.lowercased() == "png" }

        if pngURLs.isEmpty {
            error.pointee = "No PNG files found" as NSString
            return
        }

        // Show folder picker and convert
        DispatchQueue.main.async {
            self.showFolderPickerAndConvert(pngURLs)
        }
    }

    private func handleServiceFiles(_ filePaths: [String]) {
        let pngURLs = filePaths.compactMap { URL(fileURLWithPath: $0) }.filter { $0.pathExtension.lowercased() == "png" }

        if pngURLs.isEmpty {
            NSApplication.shared.terminate(nil)
            return
        }

        // Show folder picker and convert
        DispatchQueue.main.async {
            self.showFolderPickerAndConvert(pngURLs)
        }
    }

    private func showFolderPickerAndConvert(_ pngURLs: [URL]) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select output directory for JPEG files"
        panel.prompt = "Convert"

        if panel.runModal() == .OK, let outputDir = panel.url {
            // Convert files
            Task {
                await self.convertFiles(pngURLs, to: outputDir)
            }
        } else {
            NSApplication.shared.terminate(nil)
        }
    }

    private func convertFiles(_ inputURLs: [URL], to outputDir: URL) async {
        var successCount = 0
        var errorCount = 0

        for inputURL in inputURLs {
            let filename = inputURL.deletingPathExtension().lastPathComponent + ".jpg"
            let outputURL = outputDir.appendingPathComponent(filename)

            if await convertSingleFile(from: inputURL, to: outputURL) {
                successCount += 1
            } else {
                errorCount += 1
            }
        }

        // Show notification and exit
        showNotification(successCount: successCount, errorCount: errorCount)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NSApplication.shared.terminate(nil)
        }
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

    private func showNotification(successCount: Int, errorCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "PNG to JPEG Conversion Complete"
        content.body = "\(successCount) files converted successfully, \(errorCount) failed"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "conversion-complete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
