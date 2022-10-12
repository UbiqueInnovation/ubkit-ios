//
//  BackendUrlEditor.swift
//
//
//  Created by Matthias Felix on 11.10.22.
//

import SwiftUI

@available(iOS 13.0, *)
struct BackendUrlEditor: View {
    @ObservedObject var url: BaseUrl

    var body: some View {
        VStack(alignment: .leading) {
            Text(url.title)
            TextField(url.title, text: $url.currentUrl, onEditingChanged: { isEditing in
                if !isEditing {
                    BackendDevTools.saveNewUrl(baseUrl: url, newUrl: url.currentUrl)
                }
            })
        }
    }
}
