// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public enum CouponEntitlement {
    public static let redemptionKey = "couponCodeUnlocker.isRedeemed"

    public static func isRedeemed(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: redemptionKey)
    }

    public static func setRedeemed(_ isRedeemed: Bool = true, in defaults: UserDefaults = .standard) {
        defaults.set(isRedeemed, forKey: redemptionKey)
    }
}
