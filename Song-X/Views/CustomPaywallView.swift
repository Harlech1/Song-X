import SwiftUI
import RevenueCat
import RevenueCatUI
import SafariServices
import TPackage

struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDismissButton = false
    @State private var progress: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var isWeeklySelected = true
    @State private var packages: [Package] = []
    @State private var selectedPackage: Package?
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    @State private var yearlyStrikethroughPrice: String = ""
    @State private var isTrialEligible: Bool = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = true
    @EnvironmentObject var premiumManager: TKPremiumManager
    @StateObject private var ratingManager = RatingManager.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(.xd)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .frame(width: 75, height: 75)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }

                    Text("Unlock Premium Access")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .frame(width: 20, height: 20)
                                .foregroundColor(.purple)

                            Text("Unlock all effects")
                                .font(.system(size: 18))
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "infinity")
                                .frame(width: 20, height: 20)
                                .foregroundColor(.purple)
                            Text("Unlimited song editing")
                                .font(.system(size: 18))
                        }

//                        HStack(spacing: 12) {
//                            Image(systemName: "clock.arrow.2.circlepath")
//                                .frame(width: 20, height: 20)
//                                .foregroundColor(.purple)
//                            Text("Unlimited access")
//                                .font(.system(size: 18))
//                        }

                        HStack(spacing: 12) {
                            Image(systemName: "lock.square.stack")
                                .frame(width: 20, height: 20)
                                .foregroundColor(.purple)
                            Text("Remove annoying paywalls")
                                .font(.system(size: 18))
                        }
                    }
                    .font(.headline)
                }
                .padding(.vertical, 16)
                .padding(.horizontal)

                Spacer()

                if isTrialEligible {
                    HStack {
                        Text(isWeeklySelected ? "Free Trial Enabled" : "Free Trial Disabled")
                            .font(.headline)

                        Spacer()

                        Toggle("", isOn: $isWeeklySelected)
                            .labelsHidden()
                            .onChange(of: isWeeklySelected) { newValue in
                                selectAppropriatePackage()
                            }
                            .tint(.purple)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    if isLoading {
                        ForEach(0..<3) { _ in
                            PurchaseButtonSkeleton()
                        }
                    } else {
                        ForEach(packages, id: \.identifier) { package in
                            PurchaseButton(package: package,
                                          isSelected: selectedPackage?.identifier == package.identifier,
                                          yearlyStrikethroughPrice: yearlyStrikethroughPrice,
                                          isTrialEligible: isTrialEligible) {
                                selectPackage(package)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    if let package = selectedPackage {
                        Task {
                            do {
                                let result = try await Purchases.shared.purchase(package: package)
                                if result.customerInfo.entitlements.all["Premium"]?.isActive == true {
                                    premiumManager.isPremium = true
                                    await ratingManager.requestReview()
                                    dismiss()
                                } else {
                                    print("didnt do anything??")
                                }
                            } catch {
                                print("Purchase failed: \(error)")
                            }
                        }
                    }
                }) {
                    HStack {
                        Text(isWeeklySelected && isTrialEligible ? "Start Free Trial" : "Unlock Now")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedPackage != nil ? Color.purple : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(selectedPackage == nil || isLoading)
                .padding(.horizontal)
                .redacted(reason: isLoading ? .placeholder : [])

                HStack(spacing: 4) {
                    Button("Restore") {
                        Task {
                            do {
                                let customerInfo = try await Purchases.shared.restorePurchases()
                                print("Purchases restored: \(customerInfo)")
                                if customerInfo.entitlements.all["Premium"]?.isActive == true {
                                    alertTitle = "Success"
                                    alertMessage = "Your purchases have been restored!"
                                    showingAlert = true
                                    premiumManager.isPremium = true
                                } else {
                                    alertTitle = "No Purchases Found"
                                    alertMessage = "No previous purchases were found to restore."
                                    showingAlert = true
                                }
                            } catch {
                                print("Restore failed: \(error)")
                                alertTitle = "Restore Failed"
                                alertMessage = "Failed to restore purchases. Please try again."
                                showingAlert = true
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Button("Privacy") {
                        showingPrivacy = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Button("Terms") {
                        showingTerms = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Group {
                if !showDismissButton {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .butt))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .onAppear {
                withAnimation(.linear(duration: 3)) {
                    progress = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeIn) {
                        showDismissButton = true
                    }
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.purple.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            loadPackages()
        }
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: "https://songx.turkerkizilcik.com/privacy-policy.html")!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: "https://songx.turkerkizilcik.com/terms-of-use.html")!)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                // Only dismiss if restore was successful
                if alertTitle == "Success" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func loadPackages() {
        isLoading = true
        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                if let offering = offerings.offering(identifier: "Premium") {
                    // Check trial eligibility for all packages
                    let eligibility = try await Purchases.shared.checkTrialOrIntroDiscountEligibility(
                        productIdentifiers: offering.availablePackages.map { $0.storeProduct.productIdentifier }
                    )
                    
                    DispatchQueue.main.async {
                        // Debug logging
                        print("DEBUG: All available packages:")
                        offering.availablePackages.forEach { package in
                            if let period = package.storeProduct.subscriptionPeriod {
                                print("DEBUG: Found package - ID: \(package.identifier)")
                                print("DEBUG: Period Unit: \(period.unit)")
                                print("DEBUG: Price: \(package.storeProduct.price)")
                                print("---")
                            }
                        }
                        
                        // Just use the packages as they come from RevenueCat
                        self.packages = offering.availablePackages
                        
                        print("DEBUG: Total packages count: \(self.packages.count)")
                        
                        // Sort packages to show yearly first, then monthly, then weekly
                        self.packages = offering.availablePackages.sorted { first, second in
                            let firstPriority = first.storeProduct.subscriptionPeriod?.unit == .year ? 0 :
                                              first.storeProduct.subscriptionPeriod?.unit == .month ? 1 : 2
                            let secondPriority = second.storeProduct.subscriptionPeriod?.unit == .year ? 0 :
                                               second.storeProduct.subscriptionPeriod?.unit == .month ? 1 : 2
                            return firstPriority < secondPriority
                        }
                        
                        // Check eligibility for weekly package
                        if let weeklyPackage = self.packages.first(where: { $0.storeProduct.subscriptionPeriod?.unit == .week }) {
                            print(eligibility[weeklyPackage.storeProduct.productIdentifier]?.status.description)
                            self.isTrialEligible = eligibility[weeklyPackage.storeProduct.productIdentifier]?.status == .eligible
                            print("Is trial eligible: \(self.isTrialEligible)")
                            
                            // Calculate yearly strikethrough price
                            let weeklyPrice = NSDecimalNumber(decimal: weeklyPackage.storeProduct.price).doubleValue
                            let calculatedYearlyPrice = weeklyPrice * 52.0
                            let currencySymbol = weeklyPackage.storeProduct.localizedPriceString.first ?? "$"
                            self.yearlyStrikethroughPrice = "\(currencySymbol)\(String(format: "%.2f", calculatedYearlyPrice))"
                        }
                        
                        // Select weekly by default
                        self.selectedPackage = self.packages.first { package in
                            package.storeProduct.subscriptionPeriod?.unit == .week
                        }
                        self.isWeeklySelected = true
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error loading packages: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    private func selectPackage(_ package: Package) {
        selectedPackage = package
        isWeeklySelected = package.storeProduct.subscriptionPeriod?.unit == .week
    }

    private func selectAppropriatePackage() {
        if isWeeklySelected {
            selectedPackage = packages.first { package in
                package.storeProduct.subscriptionPeriod?.unit == .week
            }
        } else {
            // Keep the currently selected package if it's not weekly
            if let currentPackage = selectedPackage,
               currentPackage.storeProduct.subscriptionPeriod?.unit != .week {
                // Keep the current selection
            } else {
                // Default to monthly if available, otherwise yearly
                selectedPackage = packages.first { package in
                    package.storeProduct.subscriptionPeriod?.unit == .month
                } ?? packages.first { package in
                    package.storeProduct.subscriptionPeriod?.unit == .year
                }
            }
        }
    }
}

struct PurchaseButton: View {
    let package: Package
    let isSelected: Bool
    let yearlyStrikethroughPrice: String
    let isTrialEligible: Bool
    let action: () -> Void
    
    private var savingsPercentage: Int? {
        guard package.storeProduct.subscriptionPeriod?.unit == .year else { 
            print("Not yearly plan")
            return nil 
        }
        
        let yearlyPrice = NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
        print("Yearly price: \(yearlyPrice)")
        print("Strikethrough price string: \(yearlyStrikethroughPrice)")
        
        // Remove any currency symbols and whitespace
        let cleanedPrice = yearlyStrikethroughPrice.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        let calculatedYearlyPrice = Double(cleanedPrice) ?? 0
        print("Calculated yearly price: \(calculatedYearlyPrice)")
        
        if calculatedYearlyPrice > 0 {
            let savings = Int(((calculatedYearlyPrice - yearlyPrice) / calculatedYearlyPrice) * 100)
            print("Savings percentage: \(savings)")
            return savings
        }
        print("Calculated price was 0")
        return nil
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(package.storeProduct.subscriptionPeriod?.unit == .week && isTrialEligible ? "3-Day Trial" : 
                             package.storeProduct.subscriptionPeriod?.unit == .week ? "Weekly Plan" :
                             package.storeProduct.subscriptionPeriod?.unit == .month ? "Monthly Plan" :
                             package.storeProduct.subscriptionPeriod?.unit == .year ? "Yearly Plan" : "Subscription")
                            .font(.headline)
                            .foregroundColor(.primary)

                        if package.storeProduct.subscriptionPeriod?.unit == .week {
                            Text(isTrialEligible ? 
                                 "then \(package.storeProduct.localizedPriceString)/week" : 
                                 "\(package.storeProduct.localizedPriceString)/week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if package.storeProduct.subscriptionPeriod?.unit == .month {
                            Text("\(package.storeProduct.localizedPriceString)/month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            (Text(yearlyStrikethroughPrice).strikethrough() + Text(" \(package.storeProduct.localizedPriceString)/year"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                    
                    if let savings = savingsPercentage {
                        Text("SAVE \(savings)%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.trailing, 8)
                    } else if package.storeProduct.subscriptionPeriod?.unit == .month {
                        Text("POPULAR ✨")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.trailing, 8)
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .purple : .secondary)
                        .font(.title3)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.purple : Color(.systemGray5), lineWidth: isSelected ? 5 : 5)
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct PurchaseButtonSkeleton: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Package Name")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Price information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 5)
        )
        .redacted(reason: .placeholder)
    }
}

private extension SubscriptionPeriod {
    var periodTitle: String {
        switch (unit, value) {
        case (.week, 1): return "3-Day Trial"
        case (.month, 1): return "Monthly Plan"
        case (.year, 1): return "Yearly Plan"
        default: return "\(value) \(unit)"
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}

#Preview {
    CustomPaywallView()
        .environment(\.locale, Locale(identifier: "de"))
}
