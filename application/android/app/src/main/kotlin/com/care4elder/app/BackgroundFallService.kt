package com.care4elder.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * FOREGROUND service for fall detection.
 * On fall: notifies Dart via MethodChannel (app open) or FlutterEngine bg isolate (app closed).
 */
class BackgroundFallService : Service() {

    private var fallManager: FallDetectionManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val TAG = "BackgroundFallService"
        private const val NOTIF_ID = 891
        private const val CHANNEL_ID = "fall_detection_service"
        private const val FALL_CALLBACK_CHANNEL = "com.care4elder.app/fall_callback"

        var mainIsolateFallCallback: (() -> Unit)? = null

        // Background engine messenger — set by FlutterBackgroundService when it starts
        var backgroundEngineCallback: (() -> Unit)? = null

        fun start(context: Context) {
            val intent = Intent(context, BackgroundFallService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BackgroundFallService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
        startForeground(NOTIF_ID, buildNotification())
        acquireWakeLock()
        startFallDetection()
        Log.d(TAG, "BackgroundFallService started as foreground")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        return START_STICKY
    }

    override fun onDestroy() {
        fallManager?.stop()
        fallManager = null
        wakeLock?.release()
        wakeLock = null
        Log.d(TAG, "BackgroundFallService destroyed")
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        val intent = Intent(applicationContext, BackgroundFallService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(intent)
        } else {
            applicationContext.startService(intent)
        }
        Log.d(TAG, "onTaskRemoved — restarting")
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Fall Detection", NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pi = PendingIntent.getActivity(this, 0, openIntent, flags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Care4Elder Active")
            .setContentText("Fall detection running")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pi)
            .build()
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, "care4elder:FallDetectionWakeLock"
        ).apply { acquire(12 * 60 * 60 * 1000L) }
    }

    private fun startFallDetection() {
        fallManager = FallDetectionManager(applicationContext)
        fallManager!!.onFallDetected = {
            Log.d(TAG, "Fall detected!")
            mainHandler.post { handleFallDetected() }
        }
        fallManager!!.start()
    }

    private fun handleFallDetected() {
        // Guard: skip if SOS already active
        val prefs = applicationContext.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        if (prefs.getBoolean("flutter.is_sos_active", false)) {
            Log.d(TAG, "SOS already active — skipping")
            return
        }

        // Only deliver via MethodChannel while the activity is resumed. When the app is only
        // minimized (onPause), the engine often does not run the Dart handler until later, so SOS
        // would not fire — use the same pending + Flutter background path as when the UI is gone.
        val mainForeground = mainIsolateFallCallback != null && MainActivity.isActivityResumed
        if (mainForeground) {
            Log.d(TAG, "Notifying main isolate (activity resumed)")
            mainIsolateFallCallback?.invoke()
        } else if (backgroundEngineCallback != null && MainActivity.isActivityResumed) {
            Log.d(TAG, "Notifying engine via background callback (resumed)")
            backgroundEngineCallback?.invoke()
        } else {
            Log.d(TAG, "UI not resumed or no callback — pending flag + Flutter bg service")
            prefs.edit()
                .putBoolean("flutter.fall_detected_pending", true)
                .putLong("flutter.fall_detected_time", System.currentTimeMillis())
                .commit()
            startFlutterBackgroundService()
        }
    }

    private fun startFlutterBackgroundService() {
        try {
            val clazz = Class.forName("id.flutter.flutter_background_service.BackgroundService")
            applicationContext.startService(Intent(applicationContext, clazz))
            Log.d(TAG, "Flutter bg service start requested")
        } catch (e: Exception) {
            Log.e(TAG, "startFlutterBackgroundService error: ${e.message}")
        }
    }
}
