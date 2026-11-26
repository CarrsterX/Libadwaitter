package com.carrster.libadwaitter.portal

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import com.carrster.libadwaitter.LibadwaitterFileProvider
import com.carrster.libadwaitter.core.UriCacheHelper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

internal class PortalChannel(
    messenger: BinaryMessenger,
    private val contextProvider: () -> Context?,
    private val activityProvider: () -> Activity?,
) : MethodCallHandler {
    private companion object {
        const val REQ_OPEN_FILES = 41001
        const val REQ_SAVE_FILE = 41002
        const val REQ_POST_NOTIFICATIONS = 41003
        const val EXTRA_NOTIF_ID = "libadwaitter_notif_id"
        const val EXTRA_NOTIF_ACTION = "libadwaitter_notif_action"
        const val EXTRA_NOTIF_PAYLOAD = "libadwaitter_notif_payload"
    }

    private val channel = MethodChannel(messenger, "libadwaitter/portal")
    private var pendingPortalResult: Result? = null
    private var pendingPortalRequestCode: Int = 0
    private var pendingNotificationPermissionResult: Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "openUri" -> openUri(call, result)
            "share" -> shareContent(call, result)
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "sendNotification" -> sendNotification(call, result)
            "withdrawNotification" -> withdrawNotification(call, result)
            "openFiles" -> openFiles(call, result)
            "saveFile" -> saveFile(call, result)
            "writeUriBytes" -> writeUriBytes(call, result)
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != pendingPortalRequestCode || pendingPortalResult == null) {
            return false
        }
        val result = pendingPortalResult!!
        pendingPortalResult = null
        pendingPortalRequestCode = 0

        if (requestCode == REQ_OPEN_FILES) {
            if (resultCode != Activity.RESULT_OK || data == null) {
                result.success(emptyList<String>())
                return true
            }
            val ctx = activityProvider() ?: contextProvider()
            val paths = mutableListOf<String>()
            val clipData = data.clipData
            if (ctx != null) {
                if (clipData != null) {
                    for (i in 0 until clipData.itemCount) {
                        clipData.getItemAt(i).uri?.let { uri ->
                            UriCacheHelper.copyUriToCache(ctx, uri)?.let { paths.add(it) }
                        }
                    }
                } else {
                    data.data?.let { uri ->
                        UriCacheHelper.copyUriToCache(ctx, uri)?.let { paths.add(it) }
                    }
                }
            }
            result.success(paths)
            return true
        }

        if (requestCode == REQ_SAVE_FILE) {
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                result.success(null)
                return true
            }
            result.success(data.data.toString())
            return true
        }

        return false
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQ_POST_NOTIFICATIONS || pendingNotificationPermissionResult == null) {
            return false
        }
        val result = pendingNotificationPermissionResult!!
        pendingNotificationPermissionResult = null
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(mapOf("status" to "granted", "value" to true))
        } else {
            result.success(
                mapOf(
                    "status" to "denied",
                    "value" to false,
                    "errorMessage" to "User denied POST_NOTIFICATIONS permission.",
                ),
            )
        }
        return true
    }

    fun handleNotificationIntent(intent: Intent?): Boolean {
        if (intent == null || !intent.hasExtra(EXTRA_NOTIF_ID)) {
            return false
        }
        val id = intent.getStringExtra(EXTRA_NOTIF_ID) ?: return false
        val actionId = intent.getStringExtra(EXTRA_NOTIF_ACTION) ?: ""
        val payload = intent.getStringExtra(EXTRA_NOTIF_PAYLOAD) ?: ""

        intent.removeExtra(EXTRA_NOTIF_ID)
        intent.removeExtra(EXTRA_NOTIF_ACTION)
        intent.removeExtra(EXTRA_NOTIF_PAYLOAD)

        val ctx = activityProvider() ?: contextProvider()
        val nm = ctx?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        nm?.cancel(id.hashCode())

        channel.invokeMethod(
            "onNotificationAction",
            mapOf(
                "id" to id,
                "actionId" to actionId,
                "payload" to payload,
            ),
        )
        return true
    }

    private fun openUri(call: MethodCall, result: Result) {
        val uriStr = call.argument<String>("uri")
        if (uriStr.isNullOrBlank()) {
            result.success(mapOf("status" to "error", "errorMessage" to "Missing URI."))
            return
        }
        val act = activityProvider()
        val ctx = act ?: contextProvider()
        if (ctx == null) {
            result.success(mapOf("status" to "error", "errorMessage" to "No active Android context."))
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriStr)).apply {
                if (act == null) {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            ctx.startActivity(intent)
            result.success(mapOf("status" to "granted"))
        } catch (_: ActivityNotFoundException) {
            result.success(
                mapOf(
                    "status" to "error",
                    "errorMessage" to "No application found to open URI: $uriStr",
                ),
            )
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "status" to "error",
                    "errorMessage" to (e.message ?: "Failed to open URI."),
                ),
            )
        }
    }

    private fun requestNotificationPermission(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(mapOf("status" to "granted", "value" to true))
            return
        }
        val act = activityProvider()
        val ctx = act ?: contextProvider()
        if (ctx == null) {
            result.success(mapOf("status" to "error", "errorMessage" to "No active Android context."))
            return
        }
        if (ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(mapOf("status" to "granted", "value" to true))
            return
        }
        if (act == null) {
            result.success(
                mapOf(
                    "status" to "denied",
                    "value" to false,
                    "errorMessage" to "No active Android activity to request permission.",
                ),
            )
            return
        }
        if (pendingNotificationPermissionResult != null) {
            result.success(
                mapOf(
                    "status" to "error",
                    "errorMessage" to "A notification permission request is already in progress.",
                ),
            )
            return
        }
        pendingNotificationPermissionResult = result
        act.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQ_POST_NOTIFICATIONS,
        )
    }

    private fun withdrawNotification(call: MethodCall, result: Result) {
        val id = call.argument<String>("id") ?: "default"
        val ctx = activityProvider() ?: contextProvider()
        val nm = ctx?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (nm == null) {
            result.success(
                mapOf("status" to "error", "errorMessage" to "NotificationManager unavailable."),
            )
            return
        }
        nm.cancel(id.hashCode())
        result.success(mapOf("status" to "granted"))
    }

    private fun openFiles(call: MethodCall, result: Result) {
        val act = activityProvider()
        if (act == null) {
            result.error("NO_ACTIVITY", "No active Android activity.", null)
            return
        }
        if (pendingPortalResult != null) {
            result.error("BUSY", "Another file dialog is already open.", null)
            return
        }
        val multiple = call.argument<Boolean>("multiple") ?: false
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            if (multiple) {
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }
        pendingPortalResult = result
        pendingPortalRequestCode = REQ_OPEN_FILES
        act.startActivityForResult(intent, REQ_OPEN_FILES)
    }

    private fun saveFile(call: MethodCall, result: Result) {
        val act = activityProvider()
        if (act == null) {
            result.error("NO_ACTIVITY", "No active Android activity.", null)
            return
        }
        if (pendingPortalResult != null) {
            result.error("BUSY", "Another file dialog is already open.", null)
            return
        }
        val currentName = call.argument<String>("currentName") ?: "file"
        val mime = if (currentName.endsWith(".png", ignoreCase = true)) {
            "image/png"
        } else {
            "application/octet-stream"
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mime
            putExtra(Intent.EXTRA_TITLE, currentName)
        }
        pendingPortalResult = result
        pendingPortalRequestCode = REQ_SAVE_FILE
        act.startActivityForResult(intent, REQ_SAVE_FILE)
    }

    private fun writeUriBytes(call: MethodCall, result: Result) {
        val ctx = activityProvider() ?: contextProvider()
        val uriStr = call.argument<String>("uri")
        val bytes = call.argument<ByteArray>("bytes")
        if (ctx == null || uriStr == null || bytes == null) {
            result.success(false)
            return
        }
        try {
            val uri = Uri.parse(uriStr)
            ctx.contentResolver.openOutputStream(uri)?.use { out ->
                out.write(bytes)
                out.flush()
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("WRITE_ERROR", e.message, null)
        }
    }

    private fun shareContent(call: MethodCall, result: Result) {
        val act = activityProvider()
        val ctx = act ?: contextProvider()
        if (ctx == null) {
            result.success(mapOf("status" to "error", "errorMessage" to "No active Android context."))
            return
        }
        val text = call.argument<String>("text")
        val subject = call.argument<String>("subject")
        val title = call.argument<String>("title") ?: "Share"
        val filePaths = call.argument<List<String>>("filePaths") ?: emptyList()

        try {
            val authority = "${ctx.packageName}.libadwaitter.fileprovider"
            val uris = ArrayList<Uri>()
            for (path in filePaths) {
                val file = File(path)
                if (file.exists() && file.canRead()) {
                    uris.add(LibadwaitterFileProvider.registerFile(authority, file))
                }
            }

            val shareIntent = when {
                uris.size > 1 -> Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    type = "*/*"
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                uris.size == 1 -> Intent(Intent.ACTION_SEND).apply {
                    type = ctx.contentResolver.getType(uris[0]) ?: "*/*"
                    putExtra(Intent.EXTRA_STREAM, uris[0])
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                else -> Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                }
            }

            if (!text.isNullOrEmpty()) {
                shareIntent.putExtra(Intent.EXTRA_TEXT, text)
            }
            if (!subject.isNullOrEmpty()) {
                shareIntent.putExtra(Intent.EXTRA_SUBJECT, subject)
            }

            val chooser = Intent.createChooser(shareIntent, title).apply {
                if (act == null) {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            ctx.startActivity(chooser)
            result.success(mapOf("status" to "granted"))
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "status" to "error",
                    "errorMessage" to (e.message ?: "Failed to open share sheet."),
                ),
            )
        }
    }

    private fun sendNotification(call: MethodCall, result: Result) {
        val ctx = activityProvider() ?: contextProvider()
        if (ctx == null) {
            result.success(mapOf("status" to "error", "errorMessage" to "No active Android context."))
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(
                mapOf(
                    "status" to "denied",
                    "errorMessage" to "POST_NOTIFICATIONS permission not granted.",
                ),
            )
            return
        }

        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (nm == null) {
            result.success(
                mapOf("status" to "error", "errorMessage" to "NotificationManager unavailable."),
            )
            return
        }

        val id = call.argument<String>("id") ?: "default"
        val title = call.argument<String>("title") ?: ""
        val body = call.argument<String>("body")
        val priority = call.argument<String>("priority") ?: "normal"
        val payload = call.argument<String>("payload") ?: ""
        val actions = call.argument<List<Map<String, Any?>>>("actions") ?: emptyList()

        val channelId = when (priority) {
            "low" -> "libadwaitter_low"
            "high" -> "libadwaitter_high"
            "urgent" -> "libadwaitter_urgent"
            else -> "libadwaitter_default"
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = when (priority) {
                "low" -> NotificationManager.IMPORTANCE_LOW
                "high", "urgent" -> NotificationManager.IMPORTANCE_HIGH
                else -> NotificationManager.IMPORTANCE_DEFAULT
            }
            val channelName = when (priority) {
                "low" -> "Background Notifications"
                "high" -> "Important Notifications"
                "urgent" -> "Urgent Notifications"
                else -> "General Notifications"
            }
            if (nm.getNotificationChannel(channelId) == null) {
                nm.createNotificationChannel(NotificationChannel(channelId, channelName, importance))
            }
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(ctx, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(ctx)
        }

        val smallIcon = if (ctx.applicationInfo.icon != 0) {
            ctx.applicationInfo.icon
        } else {
            android.R.drawable.ic_dialog_info
        }

        builder
            .setSmallIcon(smallIcon)
            .setContentTitle(title)
            .setAutoCancel(true)

        if (!body.isNullOrEmpty()) {
            builder.setContentText(body)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            val legacyPriority = when (priority) {
                "low" -> Notification.PRIORITY_LOW
                "high" -> Notification.PRIORITY_HIGH
                "urgent" -> Notification.PRIORITY_MAX
                else -> Notification.PRIORITY_DEFAULT
            }
            @Suppress("DEPRECATION")
            builder.setPriority(legacyPriority)
        }

        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        val launchIntent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        if (launchIntent != null) {
            val contentIntent = Intent(launchIntent).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra(EXTRA_NOTIF_ID, id)
                putExtra(EXTRA_NOTIF_ACTION, "")
                putExtra(EXTRA_NOTIF_PAYLOAD, payload)
            }
            val contentPending = PendingIntent.getActivity(
                ctx,
                id.hashCode(),
                contentIntent,
                pendingFlags,
            )
            builder.setContentIntent(contentPending)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                actions.take(3).forEachIndexed { index, actionMap ->
                    val actionId = actionMap["id"] as? String ?: return@forEachIndexed
                    val label = actionMap["label"] as? String ?: return@forEachIndexed
                    val actionIntent = Intent(launchIntent).apply {
                        addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        putExtra(EXTRA_NOTIF_ID, id)
                        putExtra(EXTRA_NOTIF_ACTION, actionId)
                        putExtra(EXTRA_NOTIF_PAYLOAD, payload)
                    }
                    val reqCode = (id.hashCode() * 31) + index + 1
                    val actionPending = PendingIntent.getActivity(
                        ctx,
                        reqCode,
                        actionIntent,
                        pendingFlags,
                    )
                    @Suppress("DEPRECATION")
                    builder.addAction(Notification.Action.Builder(0, label, actionPending).build())
                }
            }
        }

        nm.notify(id.hashCode(), builder.build())
        result.success(mapOf("status" to "granted"))
    }
}
