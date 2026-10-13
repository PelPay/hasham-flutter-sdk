import Flutter
import UIKit

// HashamMobileSDK sources are included via the podspec source_files glob.

public class HashamMobileSdkPlugin: NSObject, FlutterPlugin {

    private var hasham = HashamMobile()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.chamsswitch.hasham/mobile",
            binaryMessenger: registrar.messenger()
        )
        let instance = HashamMobileSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "configure":
            var config = HashamMobileConfig()
            if let url = args?["discoveryUrl"] as? String {
                config = HashamMobileConfig(discoveryUrl: url)
            }
            if let timeout = args?["timeoutSeconds"] as? Double {
                config = HashamMobileConfig(discoveryUrl: config.discoveryUrl, timeoutSeconds: timeout)
            }
            hasham = HashamMobile(config: config)
            result(nil)

        case "getDeviceId":
            do {
                result(try hasham.deviceId())
            } catch {
                result(FlutterError(code: "NOT_ENROLLED", message: "Device not yet enrolled", details: nil))
            }

        case "isEnrolled":
            result(hasham.isEnrolled())

        case "enroll":
            guard let token = args?["enrollmentToken"] as? String else {
                result(FlutterError(code: "INVALID_PARAMS", message: "enrollmentToken is required", details: nil))
                return
            }
            Task {
                do {
                    // iOS: platformToken is unused — App Attest is triggered internally using
                    // the challenge embedded in the enrollment token.
                    let enrolled = try await self.hasham.enroll(enrollmentToken: token)
                    result(enrolled.deviceId)
                } catch {
                    result(FlutterError(code: "ENROLL_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "capturePIN":
            guard let pan = args?["pan"] as? String else {
                result(FlutterError(code: "INVALID_PARAMS", message: "pan is required", details: nil))
                return
            }
            Task { @MainActor in
                guard let vc = self.topViewController() else {
                    result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller to present from", details: nil))
                    return
                }
                do {
                    let block = try await self.hasham.capturePIN(from: vc, pan: pan)
                    result(block.hex)
                } catch {
                    result(self.flutterError(from: error))
                }
            }

        case "changePIN":
            let cardType = args?["cardType"] as? String ?? "virtual"
            Task { @MainActor in
                guard let vc = self.topViewController() else {
                    result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller to present from", details: nil))
                    return
                }
                do {
                    let changed: ChangePinResult
                    switch cardType {
                    case "virtual":
                        guard let pan = args?["pan"] as? String else {
                            result(FlutterError(code: "INVALID_PARAMS", message: "pan is required for virtual cards", details: nil))
                            return
                        }
                        changed = try await self.hasham.changePIN(from: vc, pan: pan)
                    case "physical":
                        guard let maskedPan = args?["maskedPan"] as? String else {
                            result(FlutterError(code: "INVALID_PARAMS", message: "maskedPan is required for physical cards", details: nil))
                            return
                        }
                        changed = try await self.hasham.changePIN(from: vc, maskedPan: maskedPan)
                    default:
                        result(FlutterError(code: "INVALID_PARAMS", message: "Unknown cardType: \(cardType)", details: nil))
                        return
                    }
                    result([
                        "oldPinBlock": changed.oldPinBlock,
                        "newPinBlock": changed.newPinBlock,
                        "wrappedPan":  changed.wrappedPan,
                    ])
                } catch {
                    result(self.flutterError(from: error))
                }
            }

        case "createPinBlock":
            guard let pan = args?["pan"] as? String else {
                result(FlutterError(code: "INVALID_PARAMS", message: "pan is required", details: nil))
                return
            }
            guard let pinStr = args?["pin"] as? String else {
                result(FlutterError(code: "INVALID_PARAMS", message: "pin is required", details: nil))
                return
            }
            do {
                var pin = Array(pinStr)
                let block = try hasham.createPinBlock(pan: pan, pin: &pin)
                result(block.hex)
            } catch {
                result(flutterError(from: error))
            }

        case "wrapPan":
            guard let pan = args?["pan"] as? String else {
                result(FlutterError(code: "INVALID_PARAMS", message: "pan is required", details: nil))
                return
            }
            do {
                result(try hasham.wrapPan(pan: pan))
            } catch {
                result(flutterError(from: error))
            }

        case "clearEnrollment":
            hasham.clearEnrollment()
            result(nil)

        case "sign":
            let signedAt = args?["signedAt"] as? Int ?? Int(Date().timeIntervalSince1970)
            do {
                let signed = try hasham.sign(signedAt: signedAt)
                result([
                    "deviceSignature": signed.deviceSignature,
                    "sdkSignature":    signed.sdkSignature,
                    "signedAt":        signed.signedAt,
                ])
            } catch {
                result(flutterError(from: error))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @MainActor
    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        let window = scene?.windows.first(where: { $0.isKeyWindow })
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    private func flutterError(from error: Error) -> FlutterError {
        if let mobileError = error as? HashamMobileError,
           case .invalidPin(let msg) = mobileError,
           msg.lowercased().contains("cancel") {
            return FlutterError(code: "CANCELLED", message: "PIN entry cancelled", details: nil)
        }
        return FlutterError(code: "SDK_ERROR", message: error.localizedDescription, details: nil)
    }
}
