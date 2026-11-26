package com.carrster.libadwaitter.settings

import android.app.UiModeManager
import android.content.Context
import android.database.ContentObserver
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

internal class SettingsChannel(
    messenger: BinaryMessenger,
    private val contextProvider: () -> Context?,
) : MethodCallHandler {
    private val channel = MethodChannel(messenger, "libadwaitter/settings")
    private var animatorScaleObserver: ContentObserver? = null
    private var highTextContrastObserver: ContentObserver? = null
    private var contrastChangeListener: Any? = null

    init {
        channel.setMethodCallHandler(this)
        registerAnimatorScaleObserver()
        registerContrastObservers()
    }

    fun dispose() {
        unregisterAnimatorScaleObserver()
        unregisterContrastObservers()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAnimationSettings" -> result.success(buildAndroidAnimationSettingsMap())
            "getContrastSettings" -> result.success(buildAndroidContrastSettingsMap())
            else -> result.notImplemented()
        }
    }

    private fun buildAndroidAnimationSettingsMap(): Map<String, Any> {
        val ctx = contextProvider()
        val scale = if (ctx != null) {
            try {
                Settings.Global.getFloat(
                    ctx.contentResolver,
                    Settings.Global.ANIMATOR_DURATION_SCALE,
                    1.0f,
                ).coerceIn(0.0f, 10.0f)
            } catch (_: Throwable) {
                1.0f
            }
        } else {
            1.0f
        }
        return mapOf(
            "enableAnimations" to (scale > 0.0f),
            "durationFactor" to scale.toDouble(),
            "desktop" to "Android",
        )
    }

    private fun buildAndroidContrastSettingsMap(): Map<String, Any> {
        val ctx = contextProvider()
        var contrastLevel = 0.0
        var highTextContrast = false
        if (ctx != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                try {
                    val uiModeManager = ctx.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
                    if (uiModeManager != null) {
                        contrastLevel = uiModeManager.contrast.toDouble().coerceIn(0.0, 1.0)
                    }
                } catch (_: Throwable) {
                }
            }
            try {
                highTextContrast = Settings.Secure.getInt(
                    ctx.contentResolver,
                    "high_text_contrast_enabled",
                    0,
                ) == 1
            } catch (_: Throwable) {
            }
        }
        return mapOf(
            "contrastLevel" to contrastLevel,
            "highTextContrast" to highTextContrast,
        )
    }

    private fun emitContrastChanged() {
        channel.invokeMethod(
            "onContrastSettingsChanged",
            buildAndroidContrastSettingsMap(),
        )
    }

    private fun registerAnimatorScaleObserver() {
        val ctx = contextProvider() ?: return
        if (animatorScaleObserver != null) return
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                channel.invokeMethod(
                    "onAnimationSettingsChanged",
                    buildAndroidAnimationSettingsMap(),
                )
            }
        }
        try {
            ctx.contentResolver.registerContentObserver(
                Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE),
                false,
                observer,
            )
            animatorScaleObserver = observer
        } catch (_: Throwable) {
            // Ignore if restricted on older/custom ROMs
        }
    }

    private fun unregisterAnimatorScaleObserver() {
        val obs = animatorScaleObserver ?: return
        animatorScaleObserver = null
        try {
            contextProvider()?.contentResolver?.unregisterContentObserver(obs)
        } catch (_: Throwable) {
        }
    }

    private fun registerContrastObservers() {
        val ctx = contextProvider() ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            contrastChangeListener == null
        ) {
            try {
                val uiModeManager = ctx.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
                if (uiModeManager != null) {
                    val listener = UiModeManager.ContrastChangeListener { _ ->
                        emitContrastChanged()
                    }
                    uiModeManager.addContrastChangeListener(ctx.mainExecutor, listener)
                    contrastChangeListener = listener
                }
            } catch (_: Throwable) {
            }
        }
        if (highTextContrastObserver == null) {
            val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    emitContrastChanged()
                }
            }
            try {
                ctx.contentResolver.registerContentObserver(
                    Settings.Secure.getUriFor("high_text_contrast_enabled"),
                    false,
                    observer,
                )
                highTextContrastObserver = observer
            } catch (_: Throwable) {
            }
        }
    }

    private fun unregisterContrastObservers() {
        val ctx = contextProvider()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val listener = contrastChangeListener as? UiModeManager.ContrastChangeListener
            contrastChangeListener = null
            if (listener != null && ctx != null) {
                try {
                    val uiModeManager = ctx.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
                    uiModeManager?.removeContrastChangeListener(listener)
                } catch (_: Throwable) {
                }
            }
        }
        val obs = highTextContrastObserver
        highTextContrastObserver = null
        if (obs != null && ctx != null) {
            try {
                ctx.contentResolver.unregisterContentObserver(obs)
            } catch (_: Throwable) {
            }
        }
    }
}
