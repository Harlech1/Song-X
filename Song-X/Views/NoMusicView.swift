//
//  NoMusicView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 22.10.2024.
//

import SwiftUI

struct NoMusicView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "waveform.slash")
                .resizable()
                .frame(width: 50, height: 50, alignment: .center)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.purple)
            Text("No song created")
                .font(.title.bold())
            Text("Tap the button below to create your own version of any song.")
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    NoMusicView()
}
