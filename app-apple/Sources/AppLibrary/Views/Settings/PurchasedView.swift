// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct PurchasedView: View {
    @Environment(IAPObservable.self)
    private var iapObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    @State
    private var isLoading = true

    @State
    private var products: [ABI.StoreProduct] = []

    @State
    private var couponCode = ""

    @State
    private var couponMessage: String?

    @State
    private var isCouponError = false

    @State
    private var errorHandler: ErrorHandler = .default()

    public init() {
    }

    public var body: some View {
        contentView
            .withErrorHandler(errorHandler)
            .themeProgress(if: isLoading)
            .themeAnimation(on: isLoading, category: .diagnostics)
            .onLoad {
                Task {
                    do {
                        products = try await iapObservable
                            .purchasableProducts(for: Array(iapObservable.purchasedProducts))
                            .sorted {
                                $0.localizedTitle < $1.localizedTitle
                            }
                        isLoading = false
                    } catch {
                        errorHandler.handle(error)
                        isLoading = false
                    }
                }
            }
    }
}

private extension PurchasedView {
    var isEmpty: Bool {
        iapObservable.originalPurchase == nil && iapObservable.purchasedProducts.isEmpty && iapObservable.eligibleFeatures.isEmpty
    }

    var allFeatures: [ABI.AppFeature] {
        ABI.AppFeature.allCases.sorted {
            let lRank = $0.rank(with: iapObservable)
            let rRank = $1.rank(with: iapObservable)
            if lRank != rRank {
                return lRank < rRank
            }
            return $0 < $1
        }
    }
}

private extension PurchasedView {
    var contentView: some View {
#if os(macOS)
        Form(content: sectionsGroup)
            .themeForm()
#else
        List(content: sectionsGroup)
#endif
    }

    func sectionsGroup() -> some View {
        Group {
            downloadSection
            productsSection
            featuresSection
            couponSection
            if appConfiguration.bundle.distributionTarget.supportsIAP && !iapObservable.isBeta {
                restoreSection
            }
        }
    }

    var downloadSection: some View {
        iapObservable.originalPurchase.map { purchase in
            Group {
                ThemeRow(Strings.Views.Purchased.Rows.buildNumber, value: purchase.buildNumber.description)
                    .scrollableOnTV()
                ThemeRow(Strings.Global.Nouns.date, value: purchase.purchaseDate.description)
                    .scrollableOnTV()
            }
            .themeSection(header: Strings.Views.Purchased.Sections.Download.header)
        }
    }

    var productsSection: some View {
        Group {
            if !products.isEmpty {
                ForEach(products, id: \.nativeIdentifier) {
                    ThemeRow($0.localizedTitle, value: $0.localizedPrice)
                        .scrollableOnTV()
                }
            } else {
                Text(Strings.Views.Purchased.noPurchases)
            }
        }
        .themeSection(header: Strings.Global.Nouns.products)
    }

    var featuresSection: some View {
        Group {
            ForEach(allFeatures, id: \.self) { feature in
                PurchasedFeatureView(text: feature.localizedDescription, isEligible: iapObservable.isEligible(for: feature))
                    .scrollableOnTV()
            }
        }
        .themeSection(header: Strings.Global.Nouns.features)
    }

    var couponSection: some View {
        Group {
            if iapObservable.isCouponUnlocked {
                HStack {
                    Text("Paid features unlocked")
                    Spacer()
                    ThemeImage(.marked)
                }
                .foregroundStyle(.primary)
            } else {
                TextField("Coupon code", text: $couponCode)
                Button("Redeem coupon") {
                    redeemCoupon()
                }
                .disabled(couponCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let couponMessage {
                    Text(couponMessage)
                        .foregroundStyle(isCouponError ? .red : .secondary)
                }
            }
        }
        .themeSection(
            header: "Coupon code",
            footer: iapObservable.isCouponUnlocked
                ? "This device has access to all paid features."
                : "Enter a valid coupon code to unlock all paid features on this device."
        )
    }

    var restoreSection: some View {
        RestorePurchasesButton(errorHandler: errorHandler)
            .themeContainerWithSingleEntry(
                header: Strings.Views.Paywall.Sections.Restore.header,
                footer: Strings.Views.Paywall.Sections.Restore.footer,
                isAction: true
            )
    }

    func redeemCoupon() {
        if iapObservable.redeemCoupon(couponCode) {
            couponCode = ""
            couponMessage = "Coupon accepted."
            isCouponError = false
        } else {
            couponMessage = "That coupon code is invalid."
            isCouponError = true
        }
    }
}

private struct PurchasedFeatureView: View {
    let text: String

    let isEligible: Bool

    var body: some View {
        HStack {
            Text(text)
            Spacer()
            ThemeImage(isEligible ? .marked : .close)
        }
        .foregroundStyle(isEligible ? .primary : .secondary)
    }
}

// MARK: -

private extension ABI.AppFeature {
    @MainActor
    func rank(with iapObservable: IAPObservable) -> Int {
        iapObservable.isEligible(for: self) ? 0 : 1
    }
}

// MARK: - Previews

#Preview {
    PurchasedView()
        .withMockEnvironment()
}
