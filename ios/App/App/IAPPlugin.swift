import Capacitor
import StoreKit

// Capacitor plugin that bridges StoreKit to the web layer.
// JS usage:
//   const { subscribed } = await Capacitor.Plugins.IAPPlugin.getStatus();
//   const { success } = await Capacitor.Plugins.IAPPlugin.purchase();
//   await Capacitor.Plugins.IAPPlugin.restore();

@objc(IAPPlugin)
public class IAPPlugin: CAPPlugin {

    @objc func getStatus(_ call: CAPPluginCall) {
        Task { @MainActor in
            await StoreKitManager.shared.refresh()
            call.resolve(["subscribed": StoreKitManager.shared.isSubscribed])
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        Task { @MainActor in
            do {
                let success = try await StoreKitManager.shared.purchase()
                call.resolve(["success": success])
            } catch {
                call.reject("Purchase failed", nil, error)
            }
        }
    }

    @objc func restore(_ call: CAPPluginCall) {
        Task { @MainActor in
            await StoreKitManager.shared.restore()
            call.resolve(["subscribed": StoreKitManager.shared.isSubscribed])
        }
    }

    @objc func getProductInfo(_ call: CAPPluginCall) {
        Task { @MainActor in
            if let product = StoreKitManager.shared.product {
                call.resolve([
                    "id": product.id,
                    "displayName": product.displayName,
                    "description": product.description,
                    "price": product.displayPrice
                ])
            } else {
                call.reject("Product not loaded")
            }
        }
    }
}
