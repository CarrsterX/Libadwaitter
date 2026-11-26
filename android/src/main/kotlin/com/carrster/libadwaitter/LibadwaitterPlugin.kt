package com.carrster.libadwaitter

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.carrster.libadwaitter.dnd.DndChannel
import com.carrster.libadwaitter.media.MediaChannel
import com.carrster.libadwaitter.portal.PortalChannel
import com.carrster.libadwaitter.settings.SettingsChannel
import com.carrster.libadwaitter.style.StyleChannel
import com.carrster.libadwaitter.text_actions.TextActionsChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

class LibadwaitterPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.NewIntentListener,
    PluginRegistry.RequestPermissionsResultListener {

    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var styleChannel: StyleChannel? = null
    private var settingsChannel: SettingsChannel? = null
    private var portalChannel: PortalChannel? = null
    private var mediaChannel: MediaChannel? = null
    private var dndChannel: DndChannel? = null
    private var textActionsChannel: TextActionsChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        val messenger = binding.binaryMessenger
        val ctxProvider = { applicationContext }
        val actProvider = { activity }

        styleChannel = StyleChannel(messenger, ctxProvider, actProvider)
        settingsChannel = SettingsChannel(messenger, ctxProvider)
        portalChannel = PortalChannel(messenger, ctxProvider, actProvider)
        mediaChannel = MediaChannel(messenger, ctxProvider, actProvider)
        dndChannel = DndChannel(messenger)
        textActionsChannel = TextActionsChannel(messenger, ctxProvider, actProvider)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        settingsChannel?.dispose()
        mediaChannel?.dispose()
        styleChannel?.dispose()
        portalChannel?.dispose()
        dndChannel?.dispose()
        textActionsChannel?.dispose()

        settingsChannel = null
        mediaChannel = null
        styleChannel = null
        portalChannel = null
        dndChannel = null
        textActionsChannel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun attachActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addOnNewIntentListener(this)
        binding.addRequestPermissionsResultListener(this)
        styleChannel?.applySoftInputMode(binding.activity)
        dndChannel?.attach(binding.activity)
        portalChannel?.handleNotificationIntent(binding.activity.intent)
    }

    private fun detachActivity() {
        dndChannel?.detach(activity)
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (textActionsChannel?.onActivityResult(requestCode, resultCode, data) == true) {
            return true
        }
        if (portalChannel?.onActivityResult(requestCode, resultCode, data) == true) {
            return true
        }
        return false
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return portalChannel?.handleNotificationIntent(intent) ?: false
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        return portalChannel?.onRequestPermissionsResult(requestCode, grantResults) ?: false
    }
}
