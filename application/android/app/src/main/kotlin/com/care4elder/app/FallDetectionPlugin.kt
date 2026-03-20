package com.care4elder.app

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/**
 * Flutter plugin for the MAIN isolate only.
 * Provides EventChannel for foreground fall detection streaming.
 * Background fall detection is handled by BackgroundFallService (pure Kotlin).
 */
class FallDetectionPlugin : FlutterPlugin, EventChannel.StreamHandler {

    private var context: Context? = null
    private var fallManager: FallDetectionManager? = null
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        const val EVENT_CHANNEL = "com.care4elder.app/fall_detection"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val channel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        channel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        fallManager?.stop()
        fallManager = null
        context = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val ctx = context ?: return
        fallManager = FallDetectionManager(ctx)
        fallManager!!.onFallDetected = {
            eventSink?.success("fall_detected")
        }
        fallManager!!.start()
    }

    override fun onCancel(arguments: Any?) {
        fallManager?.stop()
        fallManager = null
        eventSink = null
    }
}
