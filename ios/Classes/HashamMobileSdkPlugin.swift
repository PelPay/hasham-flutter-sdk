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
            let captureTheme = pinTheme(from: args?["theme"] as? [String: Any])
            Task { @MainActor in
                guard let vc = self.topViewController() else {
                    result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller to present from", details: nil))
                    return
                }
                do {
                    let block = try await self.hasham.capturePIN(from: vc, pan: pan, theme: captureTheme)
                    result(block.hex)
                } catch {
                    result(self.flutterError(from: error))
                }
            }

        case "changePIN":
            let cardType = args?["cardType"] as? String ?? "virtual"
            let changeTheme = pinTheme(from: args?["theme"] as? [String: Any])
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
                        changed = try await self.hasham.changePIN(from: vc, pan: pan, theme: changeTheme)
                    case "physical":
                        guard let maskedPan = args?["maskedPan"] as? String else {
                            result(FlutterError(code: "INVALID_PARAMS", message: "maskedPan is required for physical cards", details: nil))
                            return
                        }
                        changed = try await self.hasham.changePIN(from: vc, maskedPan: maskedPan, theme: changeTheme)
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

    private func pinTheme(from map: [String: Any]?) -> PinTheme {
        guard let map = map else { return PinTheme() }
        var theme = PinTheme()
        if let c = map["colors"] as? [String: Any] {
            theme.colors = PinTheme.Colors(
                primary:       uiColor(from: c["primary"] as? String)       ?? theme.colors.primary,
                background:    uiColor(from: c["background"] as? String)    ?? theme.colors.background,
                keyBackground: uiColor(from: c["keyBackground"] as? String) ?? theme.colors.keyBackground,
                keyText:       uiColor(from: c["keyText"] as? String)       ?? theme.colors.keyText,
                dotFilled:     uiColor(from: c["dotFilled"] as? String)     ?? theme.colors.dotFilled,
                dotEmpty:      uiColor(from: c["dotEmpty"] as? String)      ?? theme.colors.dotEmpty,
                titleColor:    uiColor(from: c["titleColor"] as? String)    ?? theme.colors.titleColor,
                subtitleColor: uiColor(from: c["subtitleColor"] as? String) ?? theme.colors.subtitleColor
            )
        }
        if let t = map["typography"] as? [String: Any] {
            theme.typography = PinTheme.Typography(
                titleSize:    (t["titleSize"] as? CGFloat)    ?? theme.typography.titleSize,
                subtitleSize: (t["subtitleSize"] as? CGFloat) ?? theme.typography.subtitleSize,
                keySize:      (t["keySize"] as? CGFloat)      ?? theme.typography.keySize,
                fontName:     t["fontFamily"] as? String
            )
        }
        if let s = map["shape"] as? [String: Any] {
            let keyShape: PinTheme.Shape.KeyShape
            switch s["keyShape"] as? String {
            case "rounded": keyShape = .rounded
            case "square":  keyShape = .square
            default:        keyShape = .circle
            }
            theme.shape = PinTheme.Shape(
                keyShape:     keyShape,
                cornerRadius: (s["cornerRadius"] as? CGFloat) ?? theme.shape.cornerRadius
            )
        }
        if let s = map["strings"] as? [String: Any] {
            theme.strings = PinTheme.Strings(
                title:    s["title"] as? String    ?? theme.strings.title,
                subtitle: s["subtitle"] as? String ?? theme.strings.subtitle
            )
        }
        return theme
    }

    private func uiColor(from hex: String?) -> UIColor? {
        guard var h = hex else { return nil }
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6 || h.count == 8 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        if h.count == 6 {
            return UIColor(
                red:   CGFloat((rgb >> 16) & 0xFF) / 255,
                green: CGFloat((rgb >> 8)  & 0xFF) / 255,
                blue:  CGFloat(rgb         & 0xFF) / 255,
                alpha: 1
            )
        }
        return UIColor(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8)  & 0xFF) / 255,
            blue:  CGFloat(rgb         & 0xFF) / 255,
            alpha: CGFloat((rgb >> 24) & 0xFF) / 255
        )
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
