// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CryptoKit
import Foundation

enum CouponCodeUnlocker {
    private static let redemptionKey = "couponCodeUnlocker.isRedeemed"

    static var isRedeemed: Bool {
        isRedeemed(in: .standard)
    }

    static func isRedeemed(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: redemptionKey)
    }

    @discardableResult
    static func redeem(_ code: String) -> Bool {
        guard let expectedHash = configuredHash else {
            return false
        }
        return redeem(code, expectedHash: expectedHash, defaults: .standard)
    }

    @discardableResult
    static func redeem(
        _ code: String,
        expectedHash: String,
        defaults: UserDefaults
    ) -> Bool {
        guard hash(code) == expectedHash.lowercased() else {
            return false
        }
        defaults.set(true, forKey: redemptionKey)
        return true
    }

    static func hash(_ code: String) -> String {
        let digest = SHA256.hash(data: Data(normalized(code).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension CouponCodeUnlocker {
    static var configuredHash: String? {
        guard let appConfig = Bundle.main.object(forInfoDictionaryKey: "AppConfig") as? [String: Any],
              let value = appConfig["couponCodeHash"] as? String else {
            return nil
        }
        let hash = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return hash.isEmpty ? nil : hash
    }

    static func normalized(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
