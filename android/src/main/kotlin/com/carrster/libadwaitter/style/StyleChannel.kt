package com.carrster.libadwaitter.style

import android.app.Activity
import android.content.Context
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

internal class StyleChannel(
    messenger: BinaryMessenger,
    private val contextProvider: () -> Context?,
    private val activityProvider: () -> Activity?,
) : MethodCallHandler {
    private val channel = MethodChannel(messenger, "libadwaitter/style")

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    /**
     * AdwWindow / AdwDialog / AdwPopover already resize themselves from
     * `MediaQuery.viewInsets`. Letting the system also resize the surface
     * (`adjustResize`) makes the Flutter surface be recreated at a new size,
     * which flashes a blank frame when the virtual keyboard appears.
     * From API 30 the IME insets are always dispatched to Flutter, so the
     * system resize can be disabled safely.
     */
    fun applySoftInputMode(act: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            act.window.setSoftInputMode(
                WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING,
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isInMultiWindowMode" -> {
                val inMultiWindow = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    activityProvider()?.isInMultiWindowMode ?: false
                } else {
                    false
                }
                result.success(inMultiWindow)
            }
            "performSwitchHaptic" -> {
                val checked = call.argument<Boolean>("checked") ?: true
                val view = activityProvider()?.window?.decorView
                if (view != null) {
                    val effect = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        if (checked) {
                            HapticFeedbackConstants.TOGGLE_ON
                        } else {
                            HapticFeedbackConstants.TOGGLE_OFF
                        }
                    } else {
                        HapticFeedbackConstants.CONTEXT_CLICK
                    }
                    view.performHapticFeedback(
                        effect,
                        HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
                    )
                }
                result.success(null)
            }
            "setWindowBackground" -> {
                val argb = (call.argument<Number>("color"))?.toInt()
                val act = activityProvider()
                if (argb != null && act != null) {
                    act.runOnUiThread {
                        val drawable = ColorDrawable(argb)
                        act.window.setBackgroundDrawable(drawable)
                        act.window.decorView.setBackgroundColor(argb)
                    }
                }
                result.success(null)
            }
            "getSystemDynamicAccent" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val act = activityProvider()
                    val ctx = act ?: contextProvider()
                    if (ctx == null) {
                        result.success(null)
                        return
                    }
                    val res = ctx.resources
                    val theme = act?.theme ?: ctx.theme
                    val lightColor = res.getColor(android.R.color.system_accent1_600, theme)
                    val darkColor = res.getColor(android.R.color.system_accent1_400, theme)
                    result.success(
                        mapOf(
                            "light" to lightColor,
                            "dark" to darkColor,
                        ),
                    )
                } else {
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
