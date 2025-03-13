//
//  LogDevToolsView.swift
//
//
//  Created by Matthias Felix on 05.10.22.
//

import SwiftUI

@available(iOS 15.0, *)
struct LogDevToolsView: View {
    @StateObject private var extractor = DevToolsLogExtractor()

    @State private var showShareSheet = false
    @State private var filterLogs = false

    var body: some View {
        Section {
            if let error = extractor.error {
                Text("Error: \(error.localizedDescription)")
            } else if extractor.isFetching {
                HStack {
                    Spacer()
                    ProgressView("Loading logs...")
                        .progressViewStyle(.circular)
                    Spacer()
                }
            } else {
                NavigationLink("Show logs") {
                    Form {
                        Section {
                            Toggle("Filter by BundleIdentifier", isOn: $filterLogs)
                        }
                        Section {
                            List {
                                ForEach(filterLogs ? extractor.filteredEntries : extractor.entries, id: \.self) {
                                    Text($0)
                                        .padding(5)
                                }
                            }
                        }
                    }
                    .navigationTitle("Logs")
                }
                Button {
                    showShareSheet = true
                } label: {
                    Label("Export logs", systemImage: "square.and.arrow.up")
                        .labelStyle(CustomLabelStyle())
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareView(activityItems: [extractor.entries.joined(separator: "\n")])
                }
            }
        } header: {
            Text("Logs")
        }
        .onAppear {
            if !extractor.isFetching, extractor.entries.isEmpty {
                extractor.fetchEntries()
            }
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
    let activityItems: [Any]

    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ShareView>
    ) {}
}
