//
//  SliderView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 20.10.2024.
//

import SwiftUI

struct SliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let title: String
    let infoText: LocalizedStringKey
    let level: String
    let levelColor: Color
    let imageName: String
    let valueString: String
    let onEditingChanged: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                } icon: {
                    Image(systemName: imageName)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.gray)
                }
                
                InfoButton(text: infoText)

                Spacer()

                Text(valueString)
                    .font(.system(size: 16, weight: .semibold, design: .default))

            }
            Slider(value: $value, in: range) { editing in
                if !editing {
                    onEditingChanged(value)
                }
            }
            .tint(.purple)
        }
    }
}
