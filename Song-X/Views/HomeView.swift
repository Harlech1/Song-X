//
//  ContentView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 21.09.2024.
//

import SwiftUI
import RevenueCat
import RevenueCatUI
import TPackage

struct HomeView: View {
    @StateObject private var songManager = SongManager.shared
    @StateObject private var creditsManager = CreditsManager.shared
    @StateObject private var ratingManager = RatingManager.shared
    @State private var navigateToAdjustView = false
    @State private var audioFiles: [URL] = []
    @State private var showPaywall = false
    @EnvironmentObject var premiumManager: TKPremiumManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLimitAlert = false
    @State private var canDismissPaywall = false
    @State private var dismissTimer: Timer?
    let paywallDismissDelay: Double = 5.0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showInitialPaywall = false
    @State private var showSpecialOffer = false
    @AppStorage("launchCount") private var launchCount: Int = 0
    @State private var showWishKit = false
    @EnvironmentObject private var shortcutManager: ShortcutManager

    var body: some View {
        NavigationStack {
            VStack {
                if !audioFiles.isEmpty {
                    List {
                        Section(header: Text("Edited Songs")) {
                            ForEach(audioFiles, id: \.path) { fileURL in
                                HStack {
                                    Label(
                                        title: { Text(fileURL.deletingPathExtension().lastPathComponent)
                                                .lineLimit(1)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        },
                                        icon: {
                                            Image(systemName: "waveform.path")
                                                .foregroundStyle(.purple.gradient)
                                        }
                                    )
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.purple)
                                }.onTapGesture {
                                    proceedActionHandler()
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    Spacer()
                    NoMusicView()
                    Spacer()
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        if creditsManager.canEditSong(premiumManager: premiumManager) {
                            songManager.filePickerClicked.toggle()
                        } else {
                            showLimitAlert = true
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "waveform.path.badge.plus")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                            Text("Create your song")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding()
                        .background(.purple.gradient)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.vertical)
                    }
                }
            }
            .alert("Daily Limit Reached", isPresented: $showLimitAlert) {
                Button("Get Premium", role: .none) {
                    showInitialPaywall = true
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("You've reached the limit of 2 songs per day. Upgrade to premium for unlimited songs!")
            }
            .fileImporter(
                isPresented: $songManager.filePickerClicked,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false,
                onCompletion: { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            print("Success! File with \(url) is picked")
                            SongManager.shared.pickedURL = url
                            SongManager.shared.pickedSongName = url.deletingPathExtension().lastPathComponent
                            SongManager.shared.setupAudio()
                            navigateToAdjustView = true
                        }
                    case .failure(let error):
                        print("Error! File couldn't be picked. Error: \(error.localizedDescription)")
                    }
                })
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $navigateToAdjustView) {
                AdjustMusicView()
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: navigateToAdjustView) { newValue in
                if newValue == false {
                    loadAudioFiles()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !premiumManager.isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "diamond.fill")
                                    .foregroundStyle(.purple)
                                Text("\(creditsManager.remainingFreeSongs)/\(creditsManager.maxFreeSongsPerDay)")
                                    .foregroundStyle(.purple)
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                            }
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                loadAudioFiles()
                await premiumManager.checkPremiumStatus()
                
                if launchCount == 0 {
                    if await NotificationManager.shared.requestPermission() {
                        NotificationManager.shared.scheduleNotifications()
                    }
                }

                else if launchCount == 4 {
                    await ratingManager.requestReview()
                }
                
                launchCount += 1
                
                if !premiumManager.isPremium {
                    showInitialPaywall = true
                }
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { !hasSeenOnboarding },
            set: { _ in 
                hasSeenOnboarding = true
                showInitialPaywall = true
            }
        )) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $showInitialPaywall) {
            CustomPaywallView()
                .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $shortcutManager.showSpecialOffer) {
            SpecialOfferView()
        }
        .fullScreenCover(isPresented: $showSpecialOffer) {
            SpecialOfferView()
        }
        .sheet(isPresented: $shortcutManager.showWishKit) {
            NavigationStack {
                WishkitView()
            }
        }
    }

    private func loadAudioFiles() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let editedSongsURL = documentsURL.appendingPathComponent("Edited Songs")

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: editedSongsURL, includingPropertiesForKeys: nil)
            
            audioFiles = []
            
            for url in fileURLs {
                let startsWithSongX = url.lastPathComponent.hasPrefix("SongX_")
                let isM4A = url.pathExtension.lowercased() == "m4a"
                let fileExists = FileManager.default.fileExists(atPath: url.path)
                
                if startsWithSongX && isM4A && fileExists {
                    if !audioFiles.contains(url) {
                        audioFiles.append(url)
                    }
                }
            }
        } catch {
            print("Error loading audio files: \(error.localizedDescription)")
            audioFiles = []
        }
    }

    func proceedActionHandler() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Edited Songs")
        if let filesAppURL = URL(string: "shareddocuments://\(documentsUrl.path)") {
            UIApplication.shared.open(filesAppURL, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    HomeView()
}

