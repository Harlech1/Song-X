import SwiftUI

struct ThirdOnboardingView: View {
    @State var sliderValue = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("applying customizations")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)

                Text("rate, pitch, reverb, frequency etc..")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
            }

            Text("they are extremely easy, most will be sliders so don't worry.")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading) {
                HStack {
                    Label {
                        Text("Speed")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                    } icon: {
                        Image(systemName: "hare")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.gray)
                    }

                    InfoButton(text: "you found the info button! this will give informations about effects")

                    Spacer()

                    Text(String(format: "%.2f", sliderValue))
                        .font(.system(size: 16, weight: .semibold, design: .default))

                }
                Slider(value: $sliderValue, in: 0...2)
                    .tint(.purple)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    ThirdOnboardingView()
}
