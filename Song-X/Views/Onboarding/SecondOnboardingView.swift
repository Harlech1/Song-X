import SwiftUI

struct SecondOnboardingView: View {
    let effects: [Effect] = [
        Effect(name: "Nightcore", color: .red, isPremium: false),
        Effect(name: "Slowed & Reverbed", color: .purple, isPremium: true),
        Effect(name: "Sped Up", color: .blue, isPremium: true),
        Effect(name: "Bathroom Effect", color: .pink, isPremium: false)
    ]
    @State private var selectedEffect: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("applying effects") // change here
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)

                Text("slowed and reverbed, sped up, nightcore, bathroom")
                .font(.title2)
                .foregroundColor(.purple)
                .fontWeight(.semibold)
            }

            Text("clicking on those buttons will instantly edit your music.")
                .font(.title3)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16) 
            ], spacing: 16) {
                ForEach(effects) { effect in
                    Button(action: {
                        selectEffect(effect.name)
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(effect.color.gradient)
                                .aspectRatio(1.3, contentMode: .fit)
                                .cornerRadius(8)

                            if selectedEffect == effect.name {
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            VStack {
                                Spacer()
                                Text(effect.name)
                                    .font(.system(size: 14, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(12)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            

            Spacer()
        }
        .padding(.horizontal, 12)
    }

    func selectEffect(_ effectName: String) {
        if selectedEffect == effectName {
            selectedEffect = nil
            return
        }

        selectedEffect = effectName
    }
}

#Preview {
    SecondOnboardingView()
} 
