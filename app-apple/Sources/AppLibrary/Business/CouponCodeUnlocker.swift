// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CryptoKit
import Foundation

enum CouponCodeUnlocker {
    static var isRedeemed: Bool {
        if CouponEntitlement.isRedeemed() {
            return true
        }
        guard let sharedDefaults, CouponEntitlement.isRedeemed(in: sharedDefaults) else {
            return false
        }
        CouponEntitlement.setRedeemed()
        return true
    }

    static func isRedeemed(in defaults: UserDefaults) -> Bool {
        CouponEntitlement.isRedeemed(in: defaults)
    }

    @discardableResult
    static func redeem(_ code: String) -> Bool {
        guard let expectedHash = configuredHash,
              redeem(code, expectedHash: expectedHash, defaults: .standard) else {
            return false
        }
        if let sharedDefaults {
            CouponEntitlement.setRedeemed(in: sharedDefaults)
        }
        return true
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
        CouponEntitlement.setRedeemed(in: defaults)
        return true
    }

    static func hash(_ code: String) -> String {
        let digest = SHA256.hash(data: Data(normalized(code).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension CouponCodeUnlocker {
    static var appConfig: [String: Any]? {
        Bundle.main.object(forInfoDictionaryKey: "AppConfig") as? [String: Any]
    }

    static var configuredHash: String? {
        guard let value = appConfig?["couponCodeHash"] as? String else {
            return nil
        }
        let hash = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return hash.isEmpty ? nil : hash
    }

    static var sharedDefaults: UserDefaults? {
        guard let groupId = appConfig?["groupId"] as? String, !groupId.isEmpty else {
            return nil
        }
        return UserDefaults(suiteName: groupId)
    }

    static func normalized(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
