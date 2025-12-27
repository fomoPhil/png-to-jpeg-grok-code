# PNG to JPEG Converter

A powerful macOS application for converting PNG images to JPEG format with advanced batch processing and Finder integration.

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/language-Swift-orange)
![Xcode](https://img.shields.io/badge/IDE-Xcode-blue)

## Features

### 🖥️ Main Application
- **Drag & Drop Interface**: Simply drag PNG files onto the app window
- **Batch Processing**: Convert multiple PNG files simultaneously
- **File Selection**: Browse and select individual files or entire folders
- **Custom Output**: Choose specific output directories for converted files
- **Progress Tracking**: Real-time progress bars and status updates
- **Smart File Limits**: Automatically handles up to 500 files at once
- **Recursive Folder Processing**: Finds PNG files in subdirectories

### 🎯 Finder Integration
- **Contextual Menu**: Right-click PNG files in Finder for instant conversion
- **Quick Action**: "Quick Convert to JPEG" appears in Services menu
- **Batch Folder Selection**: Choose output directory for multiple files
- **System Notifications**: Completion alerts with success/failure counts

### ⚙️ Technical Features
- **High Quality**: 95% JPEG quality for optimal balance of size and clarity
- **Async Processing**: Non-blocking conversion keeps UI responsive
- **Error Handling**: Comprehensive error reporting and graceful failure handling
- **User Notifications**: macOS notifications for completion status
- **Auto-Termination**: Services automatically close after processing

## Screenshots

*Coming soon - screenshots of the drag-and-drop interface and Finder contextual menu*

## Installation

### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later (for building from source)

### Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/fomoPhil/png-to-jpeg-grok-code.git
   cd png-to-jpeg-grok-code
   ```

2. **Install dependencies:**
   - The project uses only standard macOS frameworks (SwiftUI, AppKit, CoreImage)
   - No external dependencies required

3. **Open in Xcode:**
   ```bash
   open PNGToJPEG.xcodeproj
   ```

4. **Build the project:**
   - Select the `PNGToJPEG` scheme
   - Press `Cmd + B` or go to Product → Build

5. **Run the application:**
   - Press `Cmd + R` or go to Product → Run
   - Or find `PNGToJPEG.app` in the Derived Data folder

### Installing Finder Integration

1. **Copy to Applications folder:**
   ```bash
   cp -r /path/to/PNGToJPEG.app /Applications/
   ```

2. **Restart Finder:**
   ```bash
   killall Finder
   ```

3. **Grant permissions** (first use):
   - macOS may prompt for accessibility permissions
   - Allow the app to control your computer

## Usage

### Main Application

#### Method 1: Drag and Drop
1. Open the PNG to JPEG Converter app
2. Drag PNG files from Finder onto the drop zone
3. Click "Convert X files" button
4. Confirm the conversion in the dialog
5. Wait for processing to complete

#### Method 2: File Selection
1. Click "Select Files" to choose individual PNG files
2. Or click "Select Folder" to process entire directories
3. Optionally set a custom output directory
4. Click "Convert X files" to start processing

#### Method 3: Command Line (Advanced)
```bash
/Applications/PNGToJPEG.app/Contents/MacOS/PNGToJPEG /path/to/file1.png /path/to/file2.png
```

### Finder Integration

#### Quick Convert via Right-Click
1. Select one or more PNG files in Finder
2. Right-click and select **Services → Quick Convert to JPEG**
3. Choose output folder in the dialog
4. Wait for conversion to complete
5. Check notifications for results

## Architecture

### Project Structure
```
PNGToJPEG/
├── App.swift              # Main app entry point and service delegate
├── ContentView.swift      # Main UI with drag-and-drop interface
├── Info.plist            # App configuration and service registration
├── project.yml           # XcodeGen configuration
└── PNGToJPEG.xcodeproj/  # Generated Xcode project
```

### Key Components

#### AppDelegate (`App.swift`)
- Handles application lifecycle
- Implements NSServices protocol for Finder integration
- Manages service requests and file processing

#### ContentView (`ContentView.swift`)
- SwiftUI-based main interface
- Drag-and-drop functionality
- File/folder selection dialogs
- Progress tracking and status display

#### Service Integration
- NSServices configuration in Info.plist
- Contextual menu registration
- Background processing for Finder requests

### Conversion Process
1. **Input Validation**: Checks file extensions and accessibility
2. **Image Processing**: Uses CoreImage for PNG to JPEG conversion
3. **Quality Settings**: 95% JPEG compression for optimal quality/size ratio
4. **Output Generation**: Creates JPEG files with same base names
5. **Notification System**: User alerts for completion status

## Development

### Requirements
- macOS 12.0+
- Xcode 14.0+
- Swift 5.7+

### Building with XcodeGen
```bash
# Regenerate Xcode project from project.yml
xcodegen

# Build with xcodebuild
xcodebuild build -project PNGToJPEG.xcodeproj -scheme PNGToJPEG
```

### Code Style
- Swift 5.7+ syntax
- SwiftUI for user interface
- AppKit for system integration
- Async/await for modern concurrency

### Testing
- Manual testing with various PNG files
- Test Finder integration by right-clicking files
- Verify batch processing with large file sets
- Test error handling with invalid files

## Contributing

This is a personal project, but feel free to:
- Report bugs via GitHub Issues
- Suggest features or improvements
- Submit pull requests for enhancements

## License

This project is open source. See individual files for license information.

## Acknowledgments

Built with:
- SwiftUI for modern macOS interfaces
- CoreImage for high-performance image processing
- macOS Services framework for Finder integration
- XcodeGen for project configuration management

---

**Last Updated**: December 27, 2025
**Version**: 1.0.0
