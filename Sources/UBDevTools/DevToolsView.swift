//
//  DevToolsView.swift
//  UBDevTools
//
//  Created by Marco Zimmermann on 30.09.22.
//

import SwiftUI
import UIKit

@available(iOS 13.0, *)
public class DevToolsViewController : UIHostingController<DevToolsView> {
    // MARK: - Init
    
    public init() {
        super.init(rootView: DevToolsView())
    }

    // MARK: - Init?

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.0, *)
public struct DevToolsView : View {
    private var contentView : some View {
        Form {
            Section(header: Text("User Defaults")) {
                Button("Clear UserDefaults") { UserDefaultsDevTools.clearUserDefaults() }
            }
            Section(header: Text("Finger Tips")) {
                Toggle("Show finger tips", isOn: Binding(get: { showFingerTips }, set: { showFingerTips = $0 }))
            }
            Section(header: Text("Localization")) {
                Toggle("Show localization keys", isOn: Binding(get: { showLocalizationKeys }, set: { showLocalizationKeys = $0 }))
            }
        }
    }

    // MARK: - Body

    public var body : some View {
        NavigationView {
            if #available(iOS 14.0, *) {
                contentView.navigationTitle("DevTools")
            } else {
                contentView.navigationBarTitle(Text("DevTools"))
            }
        }
    }

    // MARK: - State handling

    @State private var showFingerTips : Bool = false {
        didSet { FingerTipsDevTools.showFingerTips(showFingerTips) }
    }

    @State private var showLocalizationKeys : Bool = false {
        didSet { LocalizationDevTools.showLocalizationKeys(showLocalizationKeys) }
    }
}
