import StoreKit
import Foundation

@MainActor
class StoreManager: ObservableObject {
    @Published var isPro = false
    @Published var products: [Product] = []

    private let productIDs = [
        "com.voxnote.app.pro.monthly",
        "com.voxnote.app.pro.annual",
        "com.voxnote.app.lifetime"
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
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedStatus()
    }

    private func updatePurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result { await handle(tx) }
        }
    }

    private func handle(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            isPro = true
        }
        await transaction.finish()
    }

    var proMonthly: Product? { products.first { $0.id.contains("monthly") } }
    var proAnnual:  Product? { products.first { $0.id.contains("annual") } }
    var lifetime:   Product? { products.first { $0.id.contains("lifetime") } }
}
