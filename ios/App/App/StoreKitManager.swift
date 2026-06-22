import Foundation
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Product IDs matching App Store Connect
    static let productIDs = [
        "salessparringpro",
        "SalesSparringPremium.Plan",
        "Salessparringmax"
    ]

    enum Tier: String {
        case plan    = "salessparringpro"
        case premium = "SalesSparringPremium.Plan"
        case max     = "Salessparringmax"
        case none    = ""
    }

    @Published var isSubscribed: Bool = false
    @Published var activeTier: Tier = .none
    @Published var products: [Product] = []

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await refresh() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public

    func purchase(productID: String) async throws -> Bool {
        guard let product = products.first(where: { $0.id == productID }) else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refresh()
            return isSubscribed
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    // MARK: - Internal

    func refresh() async {
        await loadProducts()
        await checkEntitlements()
    }

    private func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            self.products = loaded.sorted { a, b in
                let order = Self.productIDs
                return (order.firstIndex(of: a.id) ?? 0) < (order.firstIndex(of: b.id) ?? 0)
            }
        } catch {
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    private func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               let tier = Tier(rawValue: transaction.productID) {
                activeTier = tier
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
        activeTier = .none
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refresh()
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
