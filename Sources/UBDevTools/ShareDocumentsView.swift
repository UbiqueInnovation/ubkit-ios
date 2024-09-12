//
//  ShareDocumentsView.swift
//
//
//  Created by Stefan Mitterrutzner on 10.10.22.
//

import AppleArchive
import SwiftUI
import System

@available(iOS 14.0, *)
struct ShareDocumentsView: View {
    @State private var archvieURL: URL?
    @State private var compressingDirectory = false
    @State private var showShareSheet = false
    @State private var showErrorAlert = false

    var body: some View {
        Section(header: Text("Export")) {
            Button {
                compressingDirectory = true
                DispatchQueue.global(qos: .userInteractive).async {
                    if let path = CompressDocumentsDirectory().compress() {
                        archvieURL = path
                        showShareSheet = true
                    } else {
                        showErrorAlert = true
                    }
                    compressingDirectory = false
                }
            } label: {
                Label("Share .documentDirectory", systemImage: "square.and.arrow.up")
                    .labelStyle(CustomLabelStyle())
            }
            .disabled(compressingDirectory == true)
            .sheet(isPresented: $showShareSheet) {
                if let url = archvieURL {
                    ShareView(url: url)
                }
            }.alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Unable to export Documents Directory"),
                    dismissButton: .cancel(Text("Ok"), action: {
                        showErrorAlert = false
                    })
                )
            }
        }
    }
}

@available(iOS 14.0, *)
private struct CustomLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            Spacer()
            configuration.icon
        }
    }
}

@available(iOS 13.0, *)
private struct ShareView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [url],
                                          applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: UIViewControllerRepresentableContext<ShareView>) {}
}

@available(iOS 14.0, *)
class CompressDocumentsDirectory {
    func compress() -> URL? {
#if !targetEnvironment(simulator)
        let archiveDestination = NSTemporaryDirectory() + "documentDirectory.aar"

        let archiveFilePath = FilePath(archiveDestination)

        guard let writeFileStream = ArchiveByteStream.fileStream(
            path: archiveFilePath,
            mode: .writeOnly,
            options: [.create],
            permissions: FilePermissions(rawValue: 0o644)
        ) else {
            return nil
        }
        defer {
            try? writeFileStream.close()
        }

        guard let compressStream = ArchiveByteStream.compressionStream(
            using: .lzfse,
            writingTo: writeFileStream
        ) else {
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

        let sourcePath = getDocumentsDirectory()
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

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
