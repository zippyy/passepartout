// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
@testable import CommonLibraryCore
import Testing

@BusinessActor
struct IAPManagerCouponTests {
    @Test
    func givenDisabledPurchases_whenVerifyPaidFeature_thenSucceeds() throws {
        let sut = IAPManager(receiptReader: FakeInAppReceiptReader())
        sut.isEnabled = false

        try sut.verify(Set([ABI.AppFeature.routing]))
    }
}
