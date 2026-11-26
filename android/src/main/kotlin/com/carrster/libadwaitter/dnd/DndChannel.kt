package com.carrster.libadwaitter.dnd

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.os.Build
import android.view.DragEvent
import android.view.View
import com.carrster.libadwaitter.LibadwaitterFileProvider
import com.carrster.libadwaitter.core.UriCacheHelper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

internal class DndChannel(
    messenger: BinaryMessenger,
) : MethodCallHandler {
    private val channel = MethodChannel(messenger, "libadwaitter/dnd")
    private var attachedActivity: Activity? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        attachedActivity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "startDrag") {
            result.success(startOutgoingDrag(call))
        } else {
            result.notImplemented()
        }
    }

    private fun startOutgoingDrag(call: MethodCall): Boolean {
        val act = attachedActivity ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false

        val filePaths = call.argument<List<String>>("files") ?: emptyList()
        val text = call.argument<String>("text")

        val authority = "${act.packageName}.libadwaitter.fileprovider"
        val items = mutableListOf<ClipData.Item>()
        val mimeTypes = mutableSetOf<String>()

        for (path in filePaths) {
            val file = File(path)
            if (file.exists() && file.canRead()) {
                val uri = LibadwaitterFileProvider.registerFile(authority, file)
                items.add(ClipData.Item(uri))
                mimeTypes.add(act.contentResolver.getType(uri) ?: "*/*")
            }
        }
        if (!text.isNullOrEmpty()) {
            items.add(ClipData.Item(text))
            mimeTypes.add(ClipDescription.MIMETYPE_TEXT_PLAIN)
        }
        if (items.isEmpty()) return false

        val label = if (filePaths.isNotEmpty()) {
            File(filePaths.first()).name
        } else {
            "Text"
        }
        val clipData = ClipData(
            ClipDescription(label, mimeTypes.toTypedArray()),
            items.first(),
        )
        for (i in 1 until items.size) {
            clipData.addItem(items[i])
        }

        val decorView = act.window.decorView
        val flags = View.DRAG_FLAG_GLOBAL or View.DRAG_FLAG_GLOBAL_URI_READ
        return try {
            decorView.startDragAndDrop(
                clipData,
                View.DragShadowBuilder(decorView),
                null,
                flags,
            )
        } catch (_: Throwable) {
            false
        }
    }

    fun attach(act: Activity) {
        attachedActivity = act
        val density = act.resources.displayMetrics.density.coerceAtLeast(1f)
        act.window.decorView.setOnDragListener { _, event ->
            when (event.action) {
                DragEvent.ACTION_DRAG_STARTED -> true
                DragEvent.ACTION_DRAG_ENTERED -> {
                    channel.invokeMethod(
                        "onDropEvent",
                        mapOf(
                            "type" to "enter",
                            "x" to (event.x / density).toDouble(),
                            "y" to (event.y / density).toDouble(),
                        ),
                    )
                    true
                }
                DragEvent.ACTION_DRAG_LOCATION -> {
                    channel.invokeMethod(
                        "onDropEvent",
                        mapOf(
                            "type" to "update",
                            "x" to (event.x / density).toDouble(),
                            "y" to (event.y / density).toDouble(),
                        ),
                    )
                    true
                }
                DragEvent.ACTION_DRAG_EXITED, DragEvent.ACTION_DRAG_ENDED -> {
                    channel.invokeMethod("onDropEvent", mapOf("type" to "leave"))
                    true
                }
                DragEvent.ACTION_DROP -> {
                    val perms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        act.requestDragAndDropPermissions(event)
                    } else {
                        null
                    }
                    try {
                        val files = mutableListOf<String>()
                        val texts = mutableListOf<String>()
                        val clip = event.clipData
                        if (clip != null) {
                            for (i in 0 until clip.itemCount) {
                                val item = clip.getItemAt(i)
                                item.uri?.let { uri ->
                                    UriCacheHelper.copyUriToCache(act, uri)?.let { files.add(it) }
                                }
                                item.text?.toString()?.takeIf { it.isNotBlank() }?.let {
                                    texts.add(it)
                                }
                            }
                        }
                        val payload = mutableMapOf<String, Any>(
                            "type" to "drop",
                            "x" to (event.x / density).toDouble(),
                            "y" to (event.y / density).toDouble(),
                        )
                        if (files.isNotEmpty()) {
                            payload["files"] = files
                        }
                        if (texts.isNotEmpty()) {
                            payload["text"] = texts.joinToString("\n")
                        }
                        channel.invokeMethod("onDropEvent", payload)
                    } finally {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            perms?.release()
                        }
                    }
                    true
                }
                else -> false
            }
        }
    }

    fun detach(act: Activity?) {
        act?.window?.decorView?.setOnDragListener(null)
        if (attachedActivity == act) {
            attachedActivity = null
        }
    }
}
