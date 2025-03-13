//
//  ShareDocumentsView.swift
//
//
//  Created by Stefan Mitterrutzner on 10.10.22.
//

import AppleArchive
import SwiftUI
import System

struct ShareDocumentsView: View {
    var body: some View {
        Section(header: Text("Export")) {
            ExportDirectoryView(directory: .documentDirectory)
            ExportDirectoryView(directory: .applicationSupportDirectory)
        }
    }
}

struct ExportDirectoryView: View {
    @State private var archiveURL: URL?
    @State private var compressingDirectory = false
    @State private var showShareSheet = false
    @State private var showErrorAlert = false

    var directory: CompressDocumentsDirectory.Directory

    var body: some View {
        Button {
            compressingDirectory = true
            Task.detached(priority: .userInitiated) {
                if let path = CompressDocumentsDirectory.compress(directory: directory) {
                    Task { @MainActor in
                        archiveURL = path
                        showShareSheet = true
                        compressingDirectory = false
                    }
                } else {
                    Task { @MainActor in
                        showErrorAlert = true
                        compressingDirectory = false
                    }
                }
            }
        } label: {
            Label("Share .\(directory.rawValue)", systemImage: "square.and.arrow.up")
                .labelStyle(CustomLabelStyle())
        }
        .disabled(compressingDirectory == true)
        .sheet(isPresented: $showShareSheet) {
            if let url = archiveURL {
                ShareView(url: url)
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Unable to export Documents Directory"),
                dismissButton: .cancel(
                    Text("Ok"),
                    action: {
                        showErrorAlert = false
                    })
            )
        }
    }
}

private struct CustomLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            Spacer()
            configuration.icon
        }
    }
}

private struct ShareView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
        let vc = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        return vc
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ShareView>
    ) {}
}

enum CompressDocumentsDirectory {
    enum Directory: String {
        case documentDirectory, applicationSupportDirectory

        var path: FileManager.SearchPathDirectory {
            switch self {
                case .documentDirectory:
                    return .documentDirectory
                case .applicationSupportDirectory:
                    return .applicationSupportDirectory
            }
        }

        var url: URL {
            let paths = FileManager.default.urls(for: path, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
        }
    }

    static func compress(directory: Directory) -> URL? {
        #if !targetEnvironment(simulator)
            let archiveDestination = NSTemporaryDirectory() + directory.rawValue + ".aar"

            let archiveFilePath = FilePath(archiveDestination)

            guard
                let writeFileStream = ArchiveByteStream.fileStream(
                    path: archiveFilePath,
                    mode: .writeOnly,
                    options: [.create],
                    permissions: FilePermissions(rawValue: 0o644)
                )
            else {
                return nil
            }
            defer {
                try? writeFileStream.close()
            }

            guard
                let compressStream = ArchiveByteStream.compressionStream(
                    using: .lzfse,
                    writingTo: writeFileStream
                )
            else {
                return nil
            }
            defer {
                try? compressStream.close()
            }

            guard let encodeStream = ArchiveStream.encodeStream(writingTo: compressStream) else {
                return nil
            }
            defer {
                try? encodeStream.close()
            }

            guard let keySet = ArchiveHeader.FieldKeySet("TYP,PAT,LNK,DEV,DAT,UID,GID,MOD,FLG,MTM,BTM,CTM") else {
                return nil
            }

            let sourcePath = directory.url
            let source = FilePath(sourcePath.path)

            do {
                try encodeStream.writeDirectoryContents(
                    archiveFrom: source,
                    keySet: keySet
                )
            } catch {
                fatalError("Write directory contents failed.")
            }

            return NSURL(fileURLWithPath: archiveDestination) as URL
        #else
            fatalError("Apple Archive isn't supported on simulator https://developer.apple.com/forums/thread/665465")
        #endif
    }
}
