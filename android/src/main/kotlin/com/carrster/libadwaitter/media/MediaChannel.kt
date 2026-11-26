package com.carrster.libadwaitter.media

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

internal class MediaChannel(
    messenger: BinaryMessenger,
    private val contextProvider: () -> Context?,
    private val activityProvider: () -> Activity?,
) : MethodCallHandler {
    private companion object {
        const val ACTION_MEDIA_CONTROL = "com.carrster.libadwaitter.MEDIA_CONTROL"
        const val EXTRA_MEDIA_COMMAND = "libadwaitter_media_command"
        const val MEDIA_NOTIFICATION_ID = 41999
        const val MEDIA_CHANNEL_ID = "libadwaitter_media"
    }

    private val channel = MethodChannel(messenger, "libadwaitter/media")
    private var mediaSession: MediaSession? = null
    private var mediaReceiver: BroadcastReceiver? = null
    private var mediaTitle: String = ""
    private var mediaArtist: String = ""
    private var mediaAlbum: String = ""
    private var mediaDurationMs: Long = 0L
    private var mediaStatus: String = "stopped"
    private var mediaPositionMs: Long = 0L
    private var mediaRate: Float = 1.0f
    private var mediaLoopMode: String = "none"
    private var mediaShuffle: Boolean = false
    private var mediaCanGoNext: Boolean = true
    private var mediaCanGoPrevious: Boolean = true
    private var mediaCanPlay: Boolean = true
    private var mediaCanPause: Boolean = true
    private var mediaCanSeek: Boolean = true

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        releaseMediaSession()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setMetadata" -> {
                ensureMediaSession()
                mediaTitle = call.argument<String>("title") ?: ""
                mediaArtist = call.argument<String>("artist") ?: ""
                mediaAlbum = call.argument<String>("album") ?: ""
                val durationUs = (call.argument<Number>("durationUs"))?.toLong() ?: 0L
                mediaDurationMs = if (durationUs > 0) durationUs / 1000L else 0L
                updateAndroidMediaMetadata()
                updateAndroidMediaNotification()
                result.success(null)
            }
            "setPlaybackState" -> {
                ensureMediaSession()
                mediaStatus = call.argument<String>("status") ?: "stopped"
                val posUs = (call.argument<Number>("positionUs"))?.toLong() ?: 0L
                mediaPositionMs = if (posUs > 0) posUs / 1000L else 0L
                mediaRate = (call.argument<Number>("rate"))?.toFloat() ?: 1.0f
                mediaLoopMode = call.argument<String>("loopMode") ?: "none"
                mediaShuffle = call.argument<Boolean>("shuffle") ?: false
                mediaCanGoNext = call.argument<Boolean>("canGoNext") ?: true
                mediaCanGoPrevious = call.argument<Boolean>("canGoPrevious") ?: true
                mediaCanPlay = call.argument<Boolean>("canPlay") ?: true
                mediaCanPause = call.argument<Boolean>("canPause") ?: true
                mediaCanSeek = call.argument<Boolean>("canSeek") ?: true
                updateAndroidPlaybackState()
                updateAndroidMediaNotification()
                result.success(null)
            }
            "setPosition" -> {
                val posUs = (call.argument<Number>("positionUs"))?.toLong() ?: 0L
                mediaPositionMs = if (posUs > 0) posUs / 1000L else 0L
                updateAndroidPlaybackState()
                result.success(null)
            }
            "dispose" -> {
                releaseMediaSession()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun dispatchMediaCommand(
        command: String,
        positionUs: Long? = null,
        loopMode: String? = null,
        shuffle: Boolean? = null,
    ) {
        val args = mutableMapOf<String, Any>("command" to command)
        if (positionUs != null) {
            args["positionUs"] = positionUs
        }
        if (loopMode != null) {
            args["loopMode"] = loopMode
        }
        if (shuffle != null) {
            args["shuffle"] = shuffle
        }
        val act = activityProvider()
        if (act != null) {
            act.runOnUiThread { channel.invokeMethod("onMediaCommand", args) }
        } else {
            channel.invokeMethod("onMediaCommand", args)
        }
    }

    private fun ensureMediaSession() {
        val ctx = activityProvider() ?: contextProvider() ?: return
        if (mediaSession == null) {
            val session = MediaSession(ctx, "LibadwaitterMediaSession")
            session.setCallback(
                object : MediaSession.Callback() {
                    override fun onPlay() = dispatchMediaCommand("play")
                    override fun onPause() = dispatchMediaCommand("pause")
                    override fun onStop() = dispatchMediaCommand("stop")
                    override fun onSkipToNext() = dispatchMediaCommand("next")
                    override fun onSkipToPrevious() = dispatchMediaCommand("previous")
                    override fun onSeekTo(pos: Long) = dispatchMediaCommand("setPosition", pos * 1000L)
                },
            )
            session.isActive = true
            mediaSession = session
        }
        if (mediaReceiver == null) {
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val cmd = intent?.getStringExtra(EXTRA_MEDIA_COMMAND) ?: return
                    when (cmd) {
                        "toggleShuffle" -> {
                            mediaShuffle = !mediaShuffle
                            dispatchMediaCommand("setShuffle", shuffle = mediaShuffle)
                            updateAndroidMediaNotification()
                        }
                        "cycleLoop" -> {
                            mediaLoopMode = when (mediaLoopMode) {
                                "none" -> "playlist"
                                "playlist" -> "track"
                                else -> "none"
                            }
                            dispatchMediaCommand("setLoopMode", loopMode = mediaLoopMode)
                            updateAndroidMediaNotification()
                        }
                        else -> dispatchMediaCommand(cmd)
                    }
                }
            }
            val filter = IntentFilter(ACTION_MEDIA_CONTROL)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ctx.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                ctx.registerReceiver(receiver, filter)
            }
            mediaReceiver = receiver
        }
    }

    private fun updateAndroidMediaMetadata() {
        val session = mediaSession ?: return
        val meta = MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, mediaTitle)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, mediaArtist)
            .putString(MediaMetadata.METADATA_KEY_ALBUM, mediaAlbum)
            .putLong(MediaMetadata.METADATA_KEY_DURATION, mediaDurationMs)
            .build()
        session.setMetadata(meta)
    }

    private fun updateAndroidPlaybackState() {
        val session = mediaSession ?: return
        val state = when (mediaStatus) {
            "playing" -> PlaybackState.STATE_PLAYING
            "paused" -> PlaybackState.STATE_PAUSED
            else -> PlaybackState.STATE_STOPPED
        }
        var actions = PlaybackState.ACTION_PLAY_PAUSE or PlaybackState.ACTION_STOP
        if (mediaCanPlay) actions = actions or PlaybackState.ACTION_PLAY
        if (mediaCanPause) actions = actions or PlaybackState.ACTION_PAUSE
        if (mediaCanGoNext) actions = actions or PlaybackState.ACTION_SKIP_TO_NEXT
        if (mediaCanGoPrevious) actions = actions or PlaybackState.ACTION_SKIP_TO_PREVIOUS
        if (mediaCanSeek) actions = actions or PlaybackState.ACTION_SEEK_TO

        val pb = PlaybackState.Builder()
            .setActions(actions)
            .setState(state, mediaPositionMs, if (state == PlaybackState.STATE_PLAYING) mediaRate else 0f)
            .build()
        session.setPlaybackState(pb)
    }

    private fun updateAndroidMediaNotification() {
        val ctx = activityProvider() ?: contextProvider() ?: return
        val session = mediaSession ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            nm.getNotificationChannel(MEDIA_CHANNEL_ID) == null
        ) {
            val ch = NotificationChannel(
                MEDIA_CHANNEL_ID,
                "Media Playback",
                NotificationManager.IMPORTANCE_LOW,
            )
            nm.createNotificationChannel(ch)
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(ctx, MEDIA_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(ctx)
        }

        val smallIcon = if (ctx.applicationInfo.icon != 0) {
            ctx.applicationInfo.icon
        } else {
            android.R.drawable.ic_media_play
        }
        val isPlaying = mediaStatus == "playing"
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        fun mediaActionIntent(command: String, reqCode: Int): PendingIntent {
            val intent = Intent(ACTION_MEDIA_CONTROL).apply {
                setPackage(ctx.packageName)
                putExtra(EXTRA_MEDIA_COMMAND, command)
            }
            return PendingIntent.getBroadcast(ctx, reqCode, intent, pendingFlags)
        }

        builder
            .setSmallIcon(smallIcon)
            .setContentTitle(mediaTitle.ifEmpty { "Media Player" })
            .setContentText(mediaArtist)
            .setOngoing(isPlaying)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setStyle(
                Notification.MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(1, 2, 3),
            )

        ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)?.let { launch ->
            val openIntent = Intent(launch).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            builder.setContentIntent(
                PendingIntent.getActivity(ctx, MEDIA_NOTIFICATION_ID, openIntent, pendingFlags),
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            @Suppress("DEPRECATION")
            builder.addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_menu_sort_by_size,
                    if (mediaShuffle) "Shuffle On" else "Shuffle",
                    mediaActionIntent("toggleShuffle", MEDIA_NOTIFICATION_ID + 4),
                ).build(),
            )
            @Suppress("DEPRECATION")
            builder.addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    mediaActionIntent("previous", MEDIA_NOTIFICATION_ID + 1),
                ).build(),
            )
            @Suppress("DEPRECATION")
            builder.addAction(
                Notification.Action.Builder(
                    if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                    if (isPlaying) "Pause" else "Play",
                    mediaActionIntent("playPause", MEDIA_NOTIFICATION_ID + 2),
                ).build(),
            )
            @Suppress("DEPRECATION")
            builder.addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_media_next,
                    "Next",
                    mediaActionIntent("next", MEDIA_NOTIFICATION_ID + 3),
                ).build(),
            )
            val loopLabel = when (mediaLoopMode) {
                "track" -> "Repeat Track"
                "playlist" -> "Repeat All"
                else -> "Repeat Off"
            }
            @Suppress("DEPRECATION")
            builder.addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_menu_rotate,
                    loopLabel,
                    mediaActionIntent("cycleLoop", MEDIA_NOTIFICATION_ID + 5),
                ).build(),
            )
        }

        nm.notify(MEDIA_NOTIFICATION_ID, builder.build())
    }

    private fun releaseMediaSession() {
        val ctx = activityProvider() ?: contextProvider()
        mediaReceiver?.let { receiver ->
            try {
                ctx?.unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
        }
        mediaReceiver = null
        mediaSession?.let { session ->
            session.isActive = false
            session.release()
        }
        mediaSession = null
        val nm = ctx?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        nm?.cancel(MEDIA_NOTIFICATION_ID)
    }
}
