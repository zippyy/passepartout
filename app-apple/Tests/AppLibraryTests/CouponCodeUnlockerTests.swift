// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import Foundation
import Testing

struct CouponCodeUnlockerTests {
    @Test
    func givenMatchingHash_whenRedeem_thenPersistsUnlock() {
        let suiteName = "CouponCodeUnlockerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let expectedHash = CouponCodeUnlocker.hash("TEST-CODE")
        #expect(CouponCodeUnlocker.redeem(
            "  test-code  ",
            expectedHash: expectedHash,
            defaults: defaults
        ))
        #expect(CouponCodeUnlocker.isRedeemed(in: defaults))
    }

    @Test
    func givenMismatchingHash_whenRedeem_thenDoesNotPersistUnlock() {
        let suiteName = "CouponCodeUnlockerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(!CouponCodeUnlocker.redeem(
            "WRONG-CODE",
            expectedHash: CouponCodeUnlocker.hash("EXPECTED-CODE"),
            defaults: defaults
        ))
        #expect(!CouponCodeUnlocker.isRedeemed(in: defaults))
    }
}
