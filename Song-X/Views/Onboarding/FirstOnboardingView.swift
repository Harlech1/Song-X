import SwiftUI
import AVKit

struct FirstOnboardingView: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VideoPlayer(player: player)
                    .disabled(true)
                    .aspectRatio(1.894, contentMode: .fit)
                    .onAppear {
                        if player == nil {
                            guard let url = Bundle.main.url(forResource: "onboardingvid", withExtension: "mp4") else { return }
                            let newPlayer = AVPlayer(url: url)
                            newPlayer.actionAtItemEnd = .none

                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                               object: newPlayer.currentItem,
                                                               queue: .main) { _ in
                                newPlayer.seek(to: .zero)
                                newPlayer.play()
                            }

                            self.player = newPlayer
                            newPlayer.play()
                        } else {
                            player?.seek(to: .zero)
                            player?.play()
                        }
                    }
                    .onDisappear {
                        player?.pause()
                    }

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("get started with SongX")
                            .font(.title)
                            .bold()
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Text("your personal music studio")
                            Image(systemName: "music.note.house.fill")
                        }
                        .font(.title2)
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                    }
                    
                    Text("we've made music editing simple and fun. no complex tools, just pure creativity. \(Image(systemName: "sparkles"))")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    FirstOnboardingView()
} 
