package com.care4elder.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.sqrt

/**
 * Pure Kotlin fall detection — no Flutter dependency.
 * Can be used from any Android Service or Activity.
 */
class FallDetectionManager(private val context: Context) {

    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var sensorListener: SensorEventListener? = null

    private val impactThreshold = 18.0f
    private val inactivityThreshold = 2.0f   // slightly higher — easier to detect stillness
    private val inactivityWindowMs = 1500L   // 1.5s window
    private val cooldownMs = 30000L

    private var lastTriggerTime = 0L
    private var verifying = false
    private var verifySamples = 0
    private var lowMotionSamples = 0
    private var verifyStartTime = 0L

    var onFallDetected: (() -> Unit)? = null

    fun start() {
        if (sensorManager != null) return // already running

        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        if (accelerometer == null) {
            android.util.Log.w("FallDetectionManager", "No accelerometer found on device")
            return
        }

        sensorListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val x = event.values[0]
                val y = event.values[1]
                val z = event.values[2]
                val magnitude = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
                val now = System.currentTimeMillis()

                if (verifying) {
                    verifySamples++
                    if (magnitude < inactivityThreshold) lowMotionSamples++

                    if (now - verifyStartTime >= inactivityWindowMs) {
                        verifying = false
                        val total = if (verifySamples == 0) 1 else verifySamples
                        val lowRatio = lowMotionSamples.toFloat() / total
                        if (lowRatio >= 0.4f) {  // 40% low motion enough to confirm fall
                            lastTriggerTime = now
                            android.util.Log.d("FallDetectionManager", "Fall confirmed!")
                            onFallDetected?.invoke()
                        }
                    }
                    return
                }

                if (magnitude > impactThreshold && now - lastTriggerTime > cooldownMs) {
                    android.util.Log.d("FallDetectionManager", "Impact detected, verifying...")
                    verifying = true
                    verifySamples = 0
                    lowMotionSamples = 0
                    verifyStartTime = now
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sensorManager?.registerListener(
            sensorListener,
            accelerometer,
            SensorManager.SENSOR_DELAY_GAME
        )
        android.util.Log.d("FallDetectionManager", "Fall detection started")
    }

    fun stop() {
        sensorListener?.let { sensorManager?.unregisterListener(it) }
        sensorListener = null
        sensorManager = null
        android.util.Log.d("FallDetectionManager", "Fall detection stopped")
    }
}
