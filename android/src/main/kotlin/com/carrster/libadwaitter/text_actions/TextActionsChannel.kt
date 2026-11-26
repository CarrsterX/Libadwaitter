package com.carrster.libadwaitter.text_actions

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.Rect
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream

internal class TextActionsChannel(
    messenger: BinaryMessenger,
    private val contextProvider: () -> Context?,
    private val activityProvider: () -> Activity?,
) : MethodCallHandler {
    private companion object {
        const val REQ_PROCESS_TEXT = 41004
    }

    private val channel = MethodChannel(messenger, "libadwaitter/text_actions")
    private var pendingProcessTextResult: Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQ_PROCESS_TEXT || pendingProcessTextResult == null) {
            return false
        }
        val res = pendingProcessTextResult!!
        pendingProcessTextResult = null
        if (resultCode == Activity.RESULT_OK && data != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val processed = data.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            res.success(processed)
        } else {
            res.success(null)
        }
        return true
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val ctx = activityProvider() ?: contextProvider()
        if (ctx == null) {
            result.success(null)
            return
        }
        when (call.method) {
            "getLocalizedLabels" -> {
                result.success(
                    mapOf(
                        "cut" to ctx.getString(android.R.string.cut),
                        "copy" to ctx.getString(android.R.string.copy),
                        "paste" to ctx.getString(android.R.string.paste),
                        "selectAll" to ctx.getString(android.R.string.selectAll),
                    ),
                )
            }
            "getTextActions" -> getTextActions(ctx, result)
            "performTextAction" -> performTextAction(call, result)
            else -> result.notImplemented()
        }
    }

    private fun getTextActions(ctx: Context, result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(emptyList<Map<String, String>>())
            return
        }
        val intent = Intent(Intent.ACTION_PROCESS_TEXT).setType("text/plain")
        val pm = ctx.packageManager
        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0L),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }
        val actions = resolved.mapNotNull { info ->
            val actInfo = info.activityInfo ?: return@mapNotNull null
            val label = info.loadLabel(pm)?.toString()?.trim()
            if (label.isNullOrEmpty()) return@mapNotNull null
            val iconBytes: ByteArray? = try {
                val baseDrawable = info.loadIcon(pm)
                    ?: pm.getApplicationIcon(actInfo.packageName)
                var useMono = false
                var drawable = baseDrawable
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                    baseDrawable is AdaptiveIconDrawable
                ) {
                    val mono = baseDrawable.monochrome?.mutate()
                    if (mono != null) {
                        mono.colorFilter = PorterDuffColorFilter(
                            Color.WHITE,
                            PorterDuff.Mode.SRC_IN,
                        )
                        drawable = mono
                        useMono = true
                    }
                }
                if (drawable != null) {
                    renderDrawable(drawable)
                        ?: if (useMono && baseDrawable != null) {
                            renderDrawable(baseDrawable)
                        } else {
                            null
                        }
                } else {
                    null
                }
            } catch (_: Exception) {
                null
            }
            val entry = mutableMapOf<String, Any>(
                "id" to "${actInfo.packageName}/${actInfo.name}",
                "label" to label,
                "packageName" to actInfo.packageName,
                "className" to actInfo.name,
            )
            if (iconBytes != null && iconBytes.isNotEmpty()) {
                entry["iconBytes"] = iconBytes
            }
            entry
        }
        result.success(actions)
    }

    private fun renderDrawable(d: Drawable): ByteArray? {
        val rawSize = 64
        val outSize = 48
        val rawBmp = Bitmap.createBitmap(rawSize, rawSize, Bitmap.Config.ARGB_8888)
        val rawCanvas = Canvas(rawBmp)
        d.setBounds(0, 0, rawSize, rawSize)
        d.draw(rawCanvas)

        val pixels = IntArray(rawSize * rawSize)
        rawBmp.getPixels(pixels, 0, rawSize, 0, 0, rawSize, rawSize)
        var minX = rawSize
        var minY = rawSize
        var maxX = -1
        var maxY = -1
        var opaqueCount = 0
        for (y in 0 until rawSize) {
            val row = y * rawSize
            for (x in 0 until rawSize) {
                if (((pixels[row + x] ushr 24) and 0xFF) > 24) {
                    opaqueCount++
                    if (x < minX) minX = x
                    if (x > maxX) maxX = x
                    if (y < minY) minY = y
                    if (y > maxY) maxY = y
                }
            }
        }
        if (opaqueCount < 16 || maxX < minX || maxY < minY) {
            rawBmp.recycle()
            return null
        }

        // Auto-trim transparent margins to a centered square so small
        // monochrome/adaptive logos fill the 48x48 output uniformly.
        val contentW = maxX - minX + 1
        val contentH = maxY - minY + 1
        val side = maxOf(contentW, contentH)
        val cx = (minX + maxX + 1) / 2.0f
        val cy = (minY + maxY + 1) / 2.0f
        val half = side / 2.0f
        val srcRect = Rect(
            (cx - half).toInt().coerceAtLeast(0),
            (cy - half).toInt().coerceAtLeast(0),
            (cx + half).toInt().coerceAtMost(rawSize),
            (cy + half).toInt().coerceAtMost(rawSize),
        )

        val outBmp = Bitmap.createBitmap(outSize, outSize, Bitmap.Config.ARGB_8888)
        val outCanvas = Canvas(outBmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        val dstRect = Rect(0, 0, outSize, outSize)
        outCanvas.drawBitmap(rawBmp, srcRect, dstRect, paint)
        rawBmp.recycle()

        val out = ByteArrayOutputStream()
        outBmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        outBmp.recycle()
        return out.toByteArray()
    }

    private fun performTextAction(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(null)
            return
        }
        val pkg = call.argument<String>("packageName")
        val cls = call.argument<String>("className")
        val text = call.argument<String>("text") ?: ""
        val readOnly = call.argument<Boolean>("readOnly") ?: false
        val act = activityProvider()
        if (pkg.isNullOrEmpty() || cls.isNullOrEmpty() || act == null) {
            result.success(null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_PROCESS_TEXT).apply {
                type = "text/plain"
                setClassName(pkg, cls)
                putExtra(Intent.EXTRA_PROCESS_TEXT, text)
                putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, readOnly)
            }
            pendingProcessTextResult = result
            act.startActivityForResult(intent, REQ_PROCESS_TEXT)
        } catch (_: Exception) {
            pendingProcessTextResult = null
            result.success(null)
        }
    }
}
