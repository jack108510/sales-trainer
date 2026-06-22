import Capacitor
import StoreKit

@objc(IAPPlugin)
public class IAPPlugin: CAPPlugin {

    @objc func getStatus(_ call: CAPPluginCall) {
        Task { @MainActor in
            await StoreKitManager.shared.refresh()
            call.resolve([
                "subscribed": StoreKitManager.shared.isSubscribed,
                "tier": StoreKitManager.shared.activeTier.rawValue
            ])
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard let productID = call.getString("productID") else {
            call.reject("Missing productID")
            return
        }
        Task { @MainActor in
            do {
                let success = try await StoreKitManager.shared.purchase(productID: productID)
                call.resolve([
                    "success": success,
                    "tier": StoreKitManager.shared.activeTier.rawValue
                ])
            } catch {
                call.reject("Purchase failed", nil, error)
            }
        }
    }

    @objc func restore(_ call: CAPPluginCall) {
        Task { @MainActor in
            await StoreKitManager.shared.restore()
            call.resolve([
                "subscribed": StoreKitManager.shared.isSubscribed,
                "tier": StoreKitManager.shared.activeTier.rawValue
            ])
        }
    }

    @objc func getProducts(_ call: CAPPluginCall) {
        Task { @MainActor in
            let products = StoreKitManager.shared.products.map { p in
                ["id": p.id, "displayName": p.displayName, "price": p.displayPrice]
            }
            call.resolve(["products": products])
        }
    }
}
