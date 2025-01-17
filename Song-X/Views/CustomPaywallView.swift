import SwiftUI

struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFeatures = false
    @State private var canDismissPaywall = false
    @State private var dismissTimer: Timer?
    
    let secondDelayOpen: Bool
    
    init(secondDelayOpen: Bool = false) {
        self.secondDelayOpen = secondDelayOpen
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Image(.snow)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .overlay(
                            LinearGradient(colors: [.clear, .black.opacity(1)],
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        .clipped()
                    
                    VStack {
                        HStack {
                            Spacer()
                            if !secondDelayOpen || canDismissPaywall {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 1)
                                }
                            }
                        }
                        .padding(.top, 48)
                        .padding(.trailing, 32)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Text("The music you love;\nReimagined. By you.")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        FeatureRow(
                            icon: "sparkles",
                            title: "Unlimited Generations",
                            gradient: [.blue, .cyan]
                        )
                        .transition(.scale.combined(with: .opacity))

                        FeatureRow(
                            icon: "wand.and.stars",
                            title: "Access All Effects",
                            gradient: [.purple, .pink]
                        )
                        .transition(.scale.combined(with: .opacity))

                        FeatureRow(
                            icon: "heart.fill",
                            title: "Support Indie Developer",
                            gradient: [.red, .pink]
                        )
                        .transition(.scale.combined(with: .opacity))

                        FeatureRow(
                            icon: "hand.tap.fill",
                            title: "No Experience Needed",
                            gradient: [.orange, .red]
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(.black)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if secondDelayOpen {
                canDismissPaywall = false
                dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    withAnimation {
                        canDismissPaywall = true
                    }
                }
            }
        }
        .onDisappear {
            dismissTimer?.invalidate()
            dismissTimer = nil
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.title2)
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 32)


        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }
}

#Preview {
    CustomPaywallView()
}
