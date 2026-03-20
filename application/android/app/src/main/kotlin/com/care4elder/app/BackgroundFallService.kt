package com.care4elder.app

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import id.flutter.flutter_background_service.FlutterBackgroundServicePlugin
import org.json.JSONObject

/**
 * Standalone background service for fall detection.
 * Runs as a regular (non-foreground) background service — the flutter_background_service
 * foreground notification already keeps the process alive.
 *
 * On fall detected:
 *   - App open  → calls mainIsolateFallCallback → MethodChannel → Dart main isolate
 *   - App closed → servicePipe.invoke → flutter_background_service Dart isolate
 */
class BackgroundFallService : Service() {

    private var fallManager: FallDetectionManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        const val TAG = "BackgroundFallService"

        var mainIsolateFallCallback: (() -> Unit)? = null

        fun start(context: Context) {
            val intent = Intent(context, BackgroundFallService::class.java)
            context.startService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BackgroundFallService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startFallDetection()
        Log.d(TAG, "BackgroundFallService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        fallManager?.stop()
        fallManager = null
        Log.d(TAG, "BackgroundFallService destroyed")
        super.onDestroy()
    }

    private fun startFallDetection() {
        fallManager = FallDetectionManager(applicationContext)
        fallManager!!.onFallDetected = {
            Log.d(TAG, "Fall detected!")
            mainHandler.post {
                if (mainIsolateFallCallback != null) {
                    // App is open — notify main Dart isolate
                    mainIsolateFallCallback?.invoke()
                } else {
                    // App is closed — notify flutter_background_service Dart isolate
                    try {
                        val json = JSONObject()
                        json.put("method", "fallDetected")
                        if (FlutterBackgroundServicePlugin.servicePipe.hasListener()) {
                            FlutterBackgroundServicePlugin.servicePipe.invoke(json)
                            Log.d(TAG, "Sent fallDetected to background isolate")
                        } else {
                            // Background isolate not running — start it, then send
                            Log.d(TAG, "Background isolate not running, starting flutter service")
                            val startIntent = Intent(applicationContext,
                                id.flutter.flutter_background_service.BackgroundService::class.java)
                            applicationContext.startService(startIntent)
                            // Retry after short delay
                            mainHandler.postDelayed({
                                try {
                                    FlutterBackgroundServicePlugin.servicePipe.invoke(json)
                                } catch (e2: Exception) {
                                    Log.e(TAG, "Retry failed: ${e2.message}")
                                }
                            }, 3000)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to send fallDetected: ${e.message}")
                    }
                }
            }
        }
        fallManager!!.start()
    }
}
