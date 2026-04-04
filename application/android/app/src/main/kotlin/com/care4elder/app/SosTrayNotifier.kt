package com.care4elder.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Drawer notification when fall is handled while [MainActivity] is not resumed (minimized / background).
 * Same channel id as Dart [showSosTriggerNotification] (`sos_fall_alert_tray`).
 */
object SosTrayNotifier {
    private const val TAG = "SosTrayNotifier"
    const val CHANNEL_ID = "sos_fall_alert_tray"
    private const val NOTIFICATION_ID = 999
    private const val REQ_OPEN = 9901
    private const val REQ_CANCEL = 9902

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "SOS Alerts",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Triggered when a fall or voice command is detected"
            enableVibration(true)
            setShowBadge(true)
        }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    fun showFallDetectedTray(context: Context) {
        ensureChannel(context)
        val appCtx = context.applicationContext
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val openIntent = Intent(appCtx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("sos_notification_action", "open_sos")
            putExtra("sos_trigger", "fall")
        }
        val openPi = PendingIntent.getActivity(appCtx, REQ_OPEN, openIntent, piFlags)

        val cancelIntent = Intent(appCtx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("sos_notification_action", "cancel_sos")
        }
        val cancelPi = PendingIntent.getActivity(appCtx, REQ_CANCEL, cancelIntent, piFlags)

        // Avoid adaptive mipmap as small icon (can fail or show blank on some OEMs).
        val notification = NotificationCompat.Builder(appCtx, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Fall Detected")
            .setContentText("A fall was detected. Tap to open SOS or use Cancel SOS.")
            .setStyle(NotificationCompat.BigTextStyle().bigText("A fall was detected. Tap to open SOS or use Cancel SOS to stop."))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(openPi)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Open SOS", openPi)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel SOS", cancelPi)
            .build()

        val nm = NotificationManagerCompat.from(appCtx)
        if (!nm.areNotificationsEnabled()) {
            Log.e(TAG, "Notifications disabled for app — enable in system settings")
        }
        try {
            nm.notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "Fall SOS tray notification posted (id=$NOTIFICATION_ID channel=$CHANNEL_ID)")
        } catch (e: SecurityException) {
            Log.e(TAG, "POST_NOTIFICATIONS denied or channel blocked: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "notify failed: ${e.message}", e)
        }
    }
}
