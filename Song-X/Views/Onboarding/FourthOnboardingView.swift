//
//  FourthOnboardingView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 19.01.2025.
//

import SwiftUI

struct FourthOnboardingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("a second to rate us?")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("ratings help us a lot \(Image(systemName: "heart.fill"))")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("also you can request features in settings, we will always read them.")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    FourthOnboardingView()
}
