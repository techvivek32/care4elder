package com.care4elder.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val controlChannel = "com.care4elder.app/fall_service_control"
    private val callbackChannel = "com.care4elder.app/fall_callback"
    private val sosIntentChannel = "com.care4elder.app/sos_intent"

    private var sosEngine: FlutterEngine? = null
    private var pendingSosTrayIntent: Intent? = null

    companion object {
        /** Used by [BackgroundFallService]: MethodChannel to the main isolate is unreliable while paused. */
        @Volatile
        var isActivityResumed: Boolean = false
    }

    override fun onResume() {
        super.onResume()
        isActivityResumed = true
    }

    override fun onPause() {
        isActivityResumed = false
        super.onPause()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureSosTrayIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.hasExtra("sos_notification_action")) {
            sosEngine?.let { deliverSosTrayToDart(it, intent) }
                ?: run { pendingSosTrayIntent = intent }
        }
    }

    private fun captureSosTrayIntent(intent: Intent?) {
        if (intent?.hasExtra("sos_notification_action") == true) {
            pendingSosTrayIntent = intent
        }
    }

    private fun flushPendingSosTray(flutterEngine: FlutterEngine) {
        val pending = pendingSosTrayIntent ?: return
        pendingSosTrayIntent = null
        deliverSosTrayToDart(flutterEngine, pending)
    }

    private fun deliverSosTrayToDart(engine: FlutterEngine, intent: Intent) {
        val action = intent.getStringExtra("sos_notification_action") ?: return
        val messenger = engine.dartExecutor.binaryMessenger
        val channel = MethodChannel(messenger, sosIntentChannel)
        when (action) {
            "open_sos" -> channel.invokeMethod("open_sos", intent.getStringExtra("sos_trigger") ?: "fall")
            "cancel_sos" -> channel.invokeMethod("cancel_sos", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sosEngine = flutterEngine

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Register FallDetectionPlugin for EventChannel (foreground use)
        flutterEngine.plugins.add(FallDetectionPlugin())

        // When app is open, forward fall events to main Dart isolate
        BackgroundFallService.mainIsolateFallCallback = {
            runOnUiThread {
                MethodChannel(messenger, callbackChannel)
                    .invokeMethod("fall_detected", null)
            }
        }

        // When app is open, also set backgroundEngineCallback to same messenger
        // so if mainIsolateFallCallback is cleared, bg callback still works
        BackgroundFallService.backgroundEngineCallback = {
            runOnUiThread {
                MethodChannel(messenger, callbackChannel)
                    .invokeMethod("fall_detected", null)
            }
        }

        // Dart calls this to start/stop the native BackgroundFallService
        MethodChannel(messenger, controlChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startFallService" -> {
                    BackgroundFallService.start(applicationContext)
                    result.success(null)
                }
                "stopFallService" -> {
                    BackgroundFallService.stop(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        flushPendingSosTray(flutterEngine)
    }

    override fun onDestroy() {
        sosEngine = null
        BackgroundFallService.mainIsolateFallCallback = null
        BackgroundFallService.backgroundEngineCallback = null
        super.onDestroy()
    }
}
