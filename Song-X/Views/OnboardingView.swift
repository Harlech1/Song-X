import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var hasRequestedNotifications = false
    @StateObject private var ratingManager = RatingManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    title: "Welcome to SongX",
                    subtitle: "Easiest song editor you will ever see.",
                    imageName: "wand.and.stars",
                    gradientColors: [.purple, .blue]
                )
                .tag(0)
                
                OnboardingPage(
                    title: "One Tap to Edit",
                    subtitle: "No music experience needed.",
                    imageName: "hand.tap.fill",
                    gradientColors: [.blue, .cyan]
                )
                .tag(1)
                
                OnboardingPage(
                    title: "Create Your First Remix",
                    subtitle: "Just pick a song and apply the effects you want. We will guide you from there.",
                    imageName: "sparkles",
                    gradientColors: [.purple, .pink]
                )
                .tag(2)
                
                OnboardingPage(
                    title: "Help Our Team 💜",
                    subtitle: "Thank you for helping us improve! Your ratings make a big difference.",
                    imageName: "star.fill",
                    gradientColors: [.orange, .yellow]
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentPage) { newPage in
                if newPage == 3 {
                    Task {
                        await ratingManager.requestReview()
                    }
                }
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { page in
                        Circle()
                            .fill(page == currentPage ? .purple : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Button {
                    if currentPage < 3 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        Task {                            
                            if !hasRequestedNotifications {
                                hasRequestedNotifications = true
                                if await NotificationManager.shared.requestPermission() {
                                    NotificationManager.shared.scheduleNotifications()
                                }
                            }
                            hasSeenOnboarding = true
                            dismiss()
                        }
                    }
                } label: {
                    Text(currentPage == 3 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 16)
        }
    }
}

private struct OnboardingPage: View {
    @State private var isGlowing = false
    
    let title: String
    let subtitle: String
    let imageName: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: imageName)
                .resizable()
                .frame(width: 100, height: 100)
                .scaledToFit()
                .foregroundStyle(.purple.gradient)
                .shadow(color: .purple.opacity(isGlowing ? 0.8 : 0.3), radius: isGlowing ? 30 : 15)
                .shadow(color: .purple.opacity(isGlowing ? 0.6 : 0.2), radius: isGlowing ? 15 : 5)
                .padding(.top, 32)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
} 
