import Foundation
import StoreKit
import Observation

/// Thin StoreKit 2 wrapper: loads the four subscription products, tracks
/// active entitlements, and exposes the resulting SubscriptionTier. Works
/// today against a local StoreKit configuration file for testing in Xcode
/// (Product > Scheme > Options > StoreKit Configuration); once real
/// products with these IDs exist in App Store Connect, no code changes
/// are needed to go live.
@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoadingProducts = false
    var lastError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var currentTier: SubscriptionTier {
        if purchasedProductIDs.contains(SubscriptionCatalog.maxMonthly.productID) ||
            purchasedProductIDs.contains(SubscriptionCatalog.maxYearly.productID) {
            return .max
        }
        if purchasedProductIDs.contains(SubscriptionCatalog.proMonthly.productID) ||
            purchasedProductIDs.contains(SubscriptionCatalog.proYearly.productID) {
            return .pro
        }
        return .free
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: SubscriptionCatalog.allProductIDs)
        } catch {
            lastError = "Couldn't load subscription options: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    @MainActor
    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }
        purchasedProductIDs = active
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
