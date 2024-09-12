//
//  DevToolsLogExtractor.swift
//
//
//  Created by Matthias Felix on 05.10.22.
//

import OSLog
import SwiftUI

@available(iOS 15.0, *)
class DevToolsLogExtractor: ObservableObject {
    private var store: OSLogStore?

    @Published var error: Error?
    @Published var isFetching = false
    @Published var entries: [String] = []
    @Published var filteredEntries: [String] = []

    private var logEntries: [OSLogEntryLog] = [] {
        didSet {
            entries = logEntries.map { "[\($0.date.formatted(date: .complete, time: .complete))] [\($0.category)] \($0.composedMessage)" }
            filteredEntries = logEntries
                .filter { $0.subsystem == Bundle.main.bundleIdentifier }
                .map { "[\($0.date.formatted(date: .complete, time: .complete))] [\($0.category)] \($0.composedMessage)" }
        }
    }

    init() {
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            self.error = error
        }
    }

    func fetchEntries() {
        guard let store else {
            return
        }

        isFetching = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let position = store.position(timeIntervalSinceLatestBoot: 1)
                let entries = try store.getEntries(at: position).compactMap { $0 as? OSLogEntryLog }

                DispatchQueue.main.async {
                    self.logEntries = entries
                    self.isFetching = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isFetching = false
                    self.error = error
                }
            }
        }
    }
}
