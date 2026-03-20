package com.care4elder.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val controlChannel = "com.care4elder.app/fall_service_control"
    private val callbackChannel = "com.care4elder.app/fall_callback"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }

    override fun onDestroy() {
        BackgroundFallService.mainIsolateFallCallback = null
        super.onDestroy()
    }
}
