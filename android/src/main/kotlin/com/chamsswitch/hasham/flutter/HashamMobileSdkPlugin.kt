package com.chamsswitch.hasham.flutter

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.chamsswitch.hasham.mobile.HashamMobile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.chamsswitch.hasham.mobile.ui.PinTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class HashamMobileSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private lateinit var appContext: Context
    private lateinit var hasham: HashamMobile
    private var activity: FragmentActivity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        hasham = HashamMobile.Builder(appContext).build()
        channel = MethodChannel(binding.binaryMessenger, "com.chamsswitch.hasham/mobile")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }
    override fun onDetachedFromActivity() { activity = null }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> {
                val discoveryUrl = call.argument<String>("discoveryUrl")
                    ?: HashamMobile.Builder.DEFAULT_DISCOVERY_URL
                val timeoutMs = call.argument<Double>("timeoutMs")?.toLong() ?: 30_000L
                hasham = HashamMobile.Builder(appContext)
                    .discoveryUrl(discoveryUrl)
                    .timeoutMs(timeoutMs)
                    .build()
                result.success(null)
            }

            "getDeviceId" -> result.success(hasham.getDeviceId())

            "isEnrolled" -> result.success(hasham.isEnrolled())

            "enroll" -> {
                val enrollmentToken = call.argument<String>("enrollmentToken") ?: run {
                    result.error("INVALID_PARAMS", "enrollmentToken is required", null)
                    return
                }
                val platformToken = call.argument<String>("platformToken") ?: run {
                    result.error("INVALID_PARAMS", "platformToken is required", null)
                    return
                }
                scope.launch {
                    try {
                        val enrolled = hasham.enroll(
                            enrollmentToken    = enrollmentToken,
                            playIntegrityToken = platformToken,
                        )
                        result.success(enrolled.deviceId)
                    } catch (e: Exception) {
                        result.error("ENROLL_ERROR", "${e::class.java.simpleName}: ${e.message}", null)
                    }
                }
            }

            "capturePIN" -> {
                val pan = call.argument<String>("pan") ?: run {
                    result.error("INVALID_PARAMS", "pan is required", null)
                    return
                }
                val theme = buildPinTheme(call.argument<Map<*, *>>("theme"))
                val act = activity ?: run {
                    result.error("NO_ACTIVITY", "No FragmentActivity available", null)
                    return
                }
                scope.launch {
                    try {
                        val block = hasham.capturePIN(activity = act, pan = pan, theme = theme)
                        result.success(block.toHex())
                    } catch (e: IllegalStateException) {
                        if (e.message == "CANCELLED") result.error("CANCELLED", "PIN entry cancelled", null)
                        else result.error("SDK_ERROR", e.message, null)
                    } catch (e: Exception) {
                        result.error("SDK_ERROR", e.message, null)
                    }
                }
            }

            "changePIN" -> {
                val cardType = call.argument<String>("cardType") ?: "virtual"
                val theme = buildPinTheme(call.argument<Map<*, *>>("theme"))
                val act = activity ?: run {
                    result.error("NO_ACTIVITY", "No FragmentActivity available", null)
                    return
                }
                scope.launch {
                    try {
                        val changed = when (cardType) {
                            "virtual" -> {
                                val pan = call.argument<String>("pan") ?: run {
                                    result.error("INVALID_PARAMS", "pan is required for virtual cards", null)
                                    return@launch
                                }
                                hasham.changePIN(activity = act, pan = pan, theme = theme)
                            }
                            "physical" -> {
                                val maskedPan = call.argument<String>("maskedPan") ?: run {
                                    result.error("INVALID_PARAMS", "maskedPan is required for physical cards", null)
                                    return@launch
                                }
                                hasham.changePIN(activity = act, maskedPan = maskedPan, theme = theme)
                            }
                            else -> {
                                result.error("INVALID_PARAMS", "Unknown cardType: $cardType", null)
                                return@launch
                            }
                        }
                        result.success(mapOf(
                            "oldPinBlock" to changed.oldPinBlock,
                            "newPinBlock" to changed.newPinBlock,
                            "wrappedPan"  to changed.wrappedPan,
                        ))
                    } catch (e: IllegalStateException) {
                        if (e.message == "CANCELLED") result.error("CANCELLED", "PIN entry cancelled", null)
                        else result.error("SDK_ERROR", e.message, null)
                    } catch (e: Exception) {
                        result.error("SDK_ERROR", e.message, null)
                    }
                }
            }

            "createPinBlock" -> {
                val pan = call.argument<String>("pan") ?: run {
                    result.error("INVALID_PARAMS", "pan is required", null)
                    return
                }
                val pinStr = call.argument<String>("pin") ?: run {
                    result.error("INVALID_PARAMS", "pin is required", null)
                    return
                }
                try {
                    val block = hasham.createPinBlock(pan, pinStr.toCharArray())
                    result.success(block.toHex())
                } catch (e: Exception) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }

            "wrapPan" -> {
                val pan = call.argument<String>("pan") ?: run {
                    result.error("INVALID_PARAMS", "pan is required", null)
                    return
                }
                try {
                    result.success(hasham.wrapPan(pan))
                } catch (e: Exception) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }

            "clearEnrollment" -> {
                hasham.clearEnrollment()
                result.success(null)
            }

            "sign" -> {
                val signedAt: Long = when (val raw = call.argument<Any>("signedAt")) {
                    is Int -> raw.toLong()
                    is Long -> raw
                    else -> System.currentTimeMillis() / 1000L
                }
                try {
                    val signed = hasham.sign(signedAt)
                    result.success(mapOf(
                        "deviceSignature" to signed.deviceSignature,
                        "sdkSignature"    to signed.sdkSignature,
                        "signedAt"        to signed.signedAt,
                    ))
                } catch (e: Exception) {
                    result.error("SDK_ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun buildPinTheme(map: Map<*, *>?): PinTheme {
        if (map == null) return PinTheme()
        val colors = (map["colors"] as? Map<*, *>)?.let { c ->
            PinTheme.Colors(
                primary       = parseColor(c["primary"] as? String),
                background    = parseColor(c["background"] as? String),
                keyBackground = parseColor(c["keyBackground"] as? String),
                keyText       = parseColor(c["keyText"] as? String),
                dotFilled     = parseColor(c["dotFilled"] as? String),
                dotEmpty      = parseColor(c["dotEmpty"] as? String),
                titleColor    = parseColor(c["titleColor"] as? String),
                subtitleColor = parseColor(c["subtitleColor"] as? String),
            )
        } ?: PinTheme.Colors()
        val typography = (map["typography"] as? Map<*, *>)?.let { t ->
            PinTheme.Typography(
                titleSizeSp    = (t["titleSize"] as? Number)?.toFloat() ?: 20f,
                subtitleSizeSp = (t["subtitleSize"] as? Number)?.toFloat() ?: 14f,
                keySizeSp      = (t["keySize"] as? Number)?.toFloat() ?: 24f,
                fontFamily     = t["fontFamily"] as? String,
            )
        } ?: PinTheme.Typography()
        val shape = (map["shape"] as? Map<*, *>)?.let { s ->
            PinTheme.Shape(
                keyShape = when (s["keyShape"] as? String) {
                    "rounded" -> PinTheme.KeyShape.ROUNDED
                    "square"  -> PinTheme.KeyShape.SQUARE
                    else      -> PinTheme.KeyShape.CIRCLE
                },
                cornerRadius = (s["cornerRadius"] as? Number)?.toFloat() ?: 8f,
            )
        } ?: PinTheme.Shape()
        val strings = (map["strings"] as? Map<*, *>)?.let { s ->
            PinTheme.Strings(
                title    = s["title"] as? String ?: "Enter your PIN",
                subtitle = s["subtitle"] as? String ?: "Keep your PIN private",
            )
        } ?: PinTheme.Strings()
        val pinLength = (map["pinLength"] as? Number)?.toInt() ?: 4
        return PinTheme(colors, typography, shape, strings, pinLength)
    }

    private fun parseColor(hex: String?): Int? =
        hex?.let { runCatching { android.graphics.Color.parseColor(it) }.getOrNull() }
}
