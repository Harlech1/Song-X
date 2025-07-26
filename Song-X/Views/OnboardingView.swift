import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @StateObject private var ratingManager = RatingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                FirstOnboardingView()
                    .tag(0)
                
                SecondOnboardingView()
                    .tag(1)
                
                ThirdOnboardingView()
                    .tag(2)

                FourthOnboardingView()
                    .tag(3)
            }
            .ignoresSafeArea(edges: .top)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onChange(of: currentPage) { newValue in
                if newValue == 3 {
                    Task {
                        await ratingManager.requestReview()
                    }
                }
            }

            Button {
                withAnimation {
                    if currentPage < 3 {
                        currentPage += 1
                    } else {
                        dismiss()
                    }
                }
            } label: {
                Text(currentPage < 3 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingView()
}
