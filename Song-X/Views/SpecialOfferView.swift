import SwiftUI
import RevenueCat
import RevenueCatUI
import TPackage

struct SpecialOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var premiumManager: TKPremiumManager
    @State private var isGlowing = false
    @State private var timeRemaining: TimeInterval = 10 * 60
    @State private var isPurchasing = false
    @State private var discountPercentage: Int = 50
    @State private var regularPrice: String = ""
    @State private var salePrice: String = ""
    @StateObject private var ratingManager = RatingManager.shared
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var isRestoring = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func calculateDiscount(offerings: Offerings?) {
        guard
            let regularPackage = offerings?.offering(identifier: "Premium")?.availablePackages.first(where: { $0.identifier == "$rc_annual" }),
            let salePackage = offerings?.offering(identifier: "Sale")?.availablePackages.first(where: { $0.identifier == "$rc_annual" })
        else {
            print("Couldn't find packages for comparison")
            return
        }
        
        let regularPriceValue = (regularPackage.storeProduct.price as NSDecimalNumber).doubleValue
        let salePriceValue = (salePackage.storeProduct.price as NSDecimalNumber).doubleValue
        
        let discount = ((regularPriceValue - salePriceValue) / regularPriceValue) * 100
        discountPercentage = Int(discount)
        regularPrice = regularPackage.storeProduct.localizedPriceString
        salePrice = salePackage.storeProduct.localizedPriceString
        
        print("Regular price: \(regularPriceValue), Sale price: \(salePriceValue), Discount: \(discountPercentage)%")
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Text("Special Launch Offer")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                            
                            Text("Don't Miss Out!")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Text("\(discountPercentage)%")
                                    .font(.system(.title, design: .rounded, weight: .black))
                                    .foregroundStyle(.white)
                                
                                VStack(alignment: .leading) {
                                    Text("OFF")
                                        .foregroundStyle(.white)
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.purple.gradient)
                            )
                            
                            VStack(spacing: 8) {
                                Text("Offer ends in")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                
                                Text(formattedTime)
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.top, 32)
                        
                        VStack(spacing: 16) {
                            Text("What's Included")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            FeatureRow(
                                icon: "infinity",
                                title: "Unlimited Songs",
                                subtitle: "Create as many remixes as you want"
                            )
                            
                            FeatureRow(
                                icon: "wand.and.stars",
                                title: "All Premium Effects",
                                subtitle: "Access to all premium effects"
                            )
                            
                            FeatureRow(
                                icon: "heart.fill",
                                title: "Support Indie Developer",
                                subtitle: "Help me create more awesome features"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Text("\(regularPrice)/year")
                            .strikethrough(color: .red)
                            .foregroundStyle(.gray)
                        
                        Text("\(salePrice)/year")
                            .foregroundStyle(.green)
                    }
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    
                    Button {
                        isPurchasing = true
                        Task {
                            do {
                                let offerings = try await Purchases.shared.getOfferings { offerings, error in
                                    if let error = error {
                                        print("Error fetching offerings: \(error)")
                                        return
                                    }
                                    
                                    if let package = offerings?.offering(identifier: "Sale")?.availablePackages.first(where: { $0.identifier == "$rc_annual" }) {
                                        Task {
                                            do {
                                                try await Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                                                    Task {
                                                        await premiumManager.checkPremiumStatus()
                                                        if premiumManager.isPremium {
                                                            dismiss()
                                                            await RatingManager.shared.requestReview()
                                                        }
                                                    }
                                                }
                                            } catch {
                                                print("Purchase failed: \(error)")
                                            }
                                        }
                                    } else {
                                        print("Weekly package not found in Sale offering")
                                    }
                                }
                            } catch {
                                print("Failed to get offerings: \(error)")
                            }
                            isPurchasing = false
                        }
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Get Premium Now")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.purple.gradient)
                        )
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    
                    Text("Subscription will renew yearly unless canceled")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    HStack(spacing: 16) {
                        Button {
                            // Handle restore
                            isRestoring = true
                            Task {
                                do {
                                    try await Purchases.shared.restorePurchases()
                                    await premiumManager.checkPremiumStatus()
                                    if premiumManager.isPremium {
                                        dismiss()
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
                        } label: {
                            Text("Restore")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Button {
                            if let url = URL(string: "https://songx.turkerkizilcik.com/privacy-policy.html") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Button {
                            if let url = URL(string: "https://songx.turkerkizilcik.com/terms-of-use.html") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Terms")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple.opacity(0.7))
                    .padding()
            }
        }
        .onAppear {
            timeRemaining = 10 * 60
            Task {
                do {
                    let offerings = try await Purchases.shared.getOfferings { offerings, error in
                        if let error = error {
                            print("Error fetching offerings for discount: \(error)")
                            return
                        }
                        calculateDiscount(offerings: offerings)
                    }
                } catch {
                    print("Failed to get offerings for discount: \(error)")
                }
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                dismiss()
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple.gradient)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SpecialOfferView()
} 
