package com.care4elder.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON") return

        val prefs: SharedPreferences = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val enabled = prefs.getBoolean("flutter.background_protection_enabled", false)
        Log.d("BootReceiver", "Boot completed, protection enabled = $enabled")

        if (enabled) {
            // Start native fall detection service directly — no Flutter engine needed
            BackgroundFallService.start(context)
            Log.d("BootReceiver", "BackgroundFallService started on boot")

            // Also restart the Flutter background service via BootRestartService
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(Intent(context, BootRestartService::class.java))
            } else {
                context.startService(Intent(context, BootRestartService::class.java))
            }
        }
    }
}
