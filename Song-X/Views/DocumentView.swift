//
//  DocumentView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 23.10.2024.
//

import SwiftUI

struct DocumentsView: View {

    var documentType: DocumentType

    var body: some View {
        ScrollView {
            ZStack {
                Text(documentType.text)
            }
        }
        .navigationTitle(documentType == .privacyPolicy ? "Privacy Policy" : "Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    DocumentsView(documentType: .privacyPolicy)
}

