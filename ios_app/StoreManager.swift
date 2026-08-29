import StoreKit
import Foundation

@MainActor
class StoreManager: ObservableObject {
    @Published var isPro = false
    @Published var products: [Product] = []

    private let productIDs = [
        "com.kokicoder.voxnote.pro.monthly",
        "com.kokicoder.voxnote.pro.annual"
    ]

    static let freeTranscriptionsPerMonth = 10

    init() {
        Task {
            await loadProducts()
            await updatePurchasedStatus()
            for await result in Transaction.updates {
                if case .verified(let tx) = result { await handle(tx) }
            }
        }
    }

    func loadProducts() async {
        products = (try? await Product.products(for: productIDs)) ?? []
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            await handle(tx)
        } else if case .userCancelled = result {
            return
        } else {
            throw StoreError.unverifiedPurchase
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedStatus()
    }

    private func updatePurchasedStatus() async {
        var hasActiveEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.revocationDate == nil,
                  (tx.expirationDate ?? .distantFuture) > .now else { continue }
            hasActiveEntitlement = true
        }
        isPro = hasActiveEntitlement
    }

    private func handle(_ transaction: Transaction) async {
        await transaction.finish()
        await updatePurchasedStatus()
    }

    var proMonthly: Product? { products.first { $0.id.contains("monthly") } }
    var proAnnual:  Product? { products.first { $0.id.contains("annual") } }
}

enum StoreError: LocalizedError {
    case unverifiedPurchase

    var errorDescription: String? { "The purchase could not be verified. Please try again." }
}

