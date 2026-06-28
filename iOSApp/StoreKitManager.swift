//
//  StoreKitManager.swift
//  RuneClicker — iOS Companion
//
//  StoreKit 2 wrapper for consumable crystal packs. Loads products, runs
//  purchases, listens for transaction updates, and credits crystals via the
//  CompanionModel. No server is needed for consumables — we verify the signed
//  transaction locally and finish it.
//

import Foundation
import StoreKit

@MainActor
public final class StoreKitManager: ObservableObject {
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchaseInProgress: String?   // product id
    @Published public var lastError: String?

    private weak var model: CompanionModel?
    private var updatesTask: Task<Void, Never>?

    private let productIDs = CrystalPack.all.map(\.id)

    public init() {}

    public func attach(model: CompanionModel) {
        self.model = model
    }

    /// Start listening for transactions and load products. Call on app launch.
    public func start() {
        updatesTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit { updatesTask?.cancel() }

    // MARK: Load

    public func loadProducts() async {
        do {
            let loaded = try await Product.products(for: productIDs)
            // Keep them in our defined pack order (small → large).
            products = productIDs.compactMap { id in loaded.first { $0.id == id } }
        } catch {
            lastError = "Couldn't load store: \(error.localizedDescription)"
        }
    }

    // MARK: Purchase

    public func purchase(_ product: Product) async {
        purchaseInProgress = product.id
        defer { purchaseInProgress = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                creditCrystals(for: transaction.productID)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: Restore (consumables aren't restorable, but we expose it for UX)

    public func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                do {
                    let transaction = try await self.checkVerified(update)
                    await self.creditCrystals(for: transaction.productID)
                    await transaction.finish()
                } catch {
                    await MainActor.run { self.lastError = "Transaction error." }
                }
            }
        }
    }

    private func creditCrystals(for productID: String) {
        let amount = CrystalPack.crystals(forProductID: productID)
        guard amount > 0 else { return }
        model?.creditCrystals(amount)
    }

    // MARK: Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error { case failedVerification }
}
