//
//  SettingsView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 23.10.2024.
//

import SwiftUI
import RevenueCat
import TPackage
import RevenueCatUI

struct SettingsView: View {
    @State private var showAlert = false
    @State private var showPaywall = false
    @State private var showGuide = false
    @State var isPremium = false
    @State private var isRestoring = false
    @EnvironmentObject var premiumManager: TKPremiumManager
    @StateObject private var ratingManager = RatingManager.shared
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: {
                        Task {
                            await premiumManager.checkPremiumStatus()
                            if !premiumManager.isPremium {
                                showPaywall = true
                            } else {
                                showAlert = true
                            }
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(premiumManager.isPremium ? "SongX Premium Activated" : "SongX Premium")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(premiumManager.isPremium ? "Thank you for your support! ♥️" : "Unlock all amazing features")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            if !premiumManager.isPremium {
                                Text("Try Now")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white))
                            }
                        }
                    }
                    .listRowBackground(Color.purple)
                }

                Section(header: Text("Subscriptions")) {
                    TKSettingsView(items: [.init(icon: "arrow.clockwise",
                                                iconColor: .white,
                                                iconBackgroundColor: .teal,
                                                title: "Restore Purchases",
                                                action: {
                        isRestoring = true
                        Task {
                            do {
                                try await Purchases.shared.restorePurchases()
                                await premiumManager.checkPremiumStatus()
                                if premiumManager.isPremium {
                                    await ratingManager.requestReview()
                                    restoreMessage = "You are already a subscriber ❤️"
                                } else {
                                    restoreMessage = "No previous purchases found."
                                }
                            } catch {
                                restoreMessage = "Failed to restore purchases. Please try again."
                            }
                            isRestoring = false
                            showRestoreAlert = true
                        }
                    })])
                }

                Section(header: Text("help make songx better")) {
                    NavigationLink(destination: WishkitView()){
                        Label(
                            title: { Text("Feature Requests") },
                            icon: { Image(systemName: "lightbulb.min.badge.exclamationmark.fill")
                                    .scaledToFit()
                                .frame(width: 20, height: 20)}
                        ).labelStyle(.colorful(.yellow))
                    }.foregroundColor(.primary)
                }

                Section(header: Text("Help us to grow")) {
                    TKSettingsView(items:
                                    [.init(icon: "square.and.arrow.up",
                                           iconColor: .white,
                                           iconBackgroundColor: .red,
                                           title: "Share App",
                                           action: {
                        TKSettingsView.shareAppLink(appUrl: "https://apps.apple.com/us/app/audio-editor-songx/id6737231550")
                    }), .init(icon: "star.fill", iconColor: .white, iconBackgroundColor: .orange, title: "Rate Us", action: {
                        TKSettingsView.openAppStoreForRating(appId: "6737231550")
                    }), .init(icon: "envelope.fill", iconColor: .white, iconBackgroundColor: .blue, title: "Feedback", action: {
                        TKSettingsView.sendEmail(to: "developerturker1@gmail.com", subject: "Feedback on SongX", body: "Hello, I'd like to share some feedback about...")
                    })])
                }

                Section(header: Text("Documents")) {
                    NavigationLink(destination: TKDocumentsView(type: .privacyPolicy, appName: "SongX", developerName: "Türker Kızılcık", email: "developerturker1@gmail.com")){
                        Label(
                            title: { Text("Privacy Policy") },
                            icon: { Image(systemName: "doc.fill") }
                        )
                    }.foregroundColor(.primary)

                    NavigationLink(destination: TKDocumentsView(type: .termsOfUse, appName: "SongX", developerName: "Türker Kızılcık", email: "developerturker1@gmail.com")){
                        Label(
                            title: { Text("Terms of Use") },
                            icon: { Image(systemName: "doc.fill") }
                        )
                    }.foregroundColor(.primary)
                }
            }
            .onAppear {
                Task {
                    await premiumManager.checkPremiumStatus()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("❤️"), message: Text("You are already a subscriber."), dismissButton: .default(Text("OK")))
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restoreMessage)
            }
            .fullScreenCover(isPresented: $showPaywall) {
                CustomPaywallView(secondDelayOpen: true)
                    .paywallFooter(condensed: true)
                    .onPurchaseCompleted { customerInfo in
                        Task {
                            await premiumManager.checkPremiumStatus()
                            if premiumManager.isPremium {
                                dismiss()
                                await ratingManager.requestReview()
                            }
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        Task {
                            await premiumManager.checkPremiumStatus()
                            if premiumManager.isPremium {
                                dismiss()
                                await ratingManager.requestReview()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SettingsView()
}
