package com.ironion.localvault

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.preference.PreferenceManager
import org.json.JSONArray

class FloatingWindowService : Service(), SensorEventListener {

    private lateinit var handler: Handler
    private lateinit var sensorManager: SensorManager
    
    // 背部敲击检测相关
    private var tapCount = 0
    private var lastTapTime = 0L
    private val tapTimeout = 500L // 两次敲击的最大时间间隔 (ms)
    
    companion object {
        private const val TAG = "FloatingWindowService"
        private const val CHANNEL_ID = "floating_channel"
        private const val NOTIFICATION_ID = 1
        
        // SharedPreferences 键
        private const val PREF_GESTURE_TAP_2_ACTION = "gesture_tap_2_action"
        private const val PREF_GESTURE_TAP_3_ACTION = "gesture_tap_3_action"
        private const val PREF_APP_WHITELIST = "app_whitelist"
        
        var isServiceRunning = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "========== FloatingWindowService is starting ==========")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        handler = Handler(Looper.getMainLooper())
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        Log.d(TAG, "Registering accelerometer sensor...")
        registerTapSensor()
        
        isServiceRunning = true
        Log.d(TAG, "========== FloatingWindowService started ==========")
    }

    private fun registerTapSensor() {
        // 注册加速度传感器来检测背部敲击
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Local Vault Floating",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Local Vault")
            .setContentText("手势唤醒服务运行中")
            .setSmallIcon(android.R.drawable.ic_menu_save)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        // 计算加速度的大小（排除重力影响，使用 delta）
        val magnitude = Math.sqrt((x * x + y * y + z * z).toDouble())
        
        // 重力大约是 9.8，所以计算相对值
        val delta = Math.abs(magnitude - 9.8)
        
        // 阈值，用于检测敲击（根据设备调整）
        val tapThreshold = 2.0

        Log.d(TAG, "Acceleration: magnitude=$magnitude, delta=$delta")

        if (delta > tapThreshold) {
            val currentTime = System.currentTimeMillis()
            
            if (currentTime - lastTapTime < tapTimeout) {
                tapCount++
                Log.d(TAG, "Tap detected, current count: $tapCount")
                
                if (tapCount == 2) {
                    handleTapGesture(2)
                    tapCount = 0
                } else if (tapCount == 3) {
                    handleTapGesture(3)
                    tapCount = 0
                }
            } else {
                tapCount = 1
                Log.d(TAG, "First tap detected, resetting counter")
            }
            
            lastTapTime = currentTime
        }
    }

    /**
     * 获取当前前台应用的包名
     */
    private fun getForegroundAppPackage(): String? {
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60,
                time
            )
            
            if (stats != null && stats.isNotEmpty()) {
                val sortedStats = stats.sortedByDescending { it.lastTimeUsed }
                sortedStats.firstOrNull()?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get foreground app", e)
            null
        }
    }
    
    /**
     * 检查当前前台应用是否在白名单中
     * 如果白名单为空，则允许所有应用
     */
    private fun isAppInWhitelist(): Boolean {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val whitelistJson = prefs.getStringSet(PREF_APP_WHITELIST, emptySet())

        // 如果Whitelist is empty, allowing all apps
        if (whitelistJson.isNullOrEmpty()) {
            Log.d(TAG, "Whitelist is empty, allowing all apps")
            return true
        }
        
        val foregroundPackage = getForegroundAppPackage() ?: return false
        Log.d(TAG, "Current foreground app: $foregroundPackage")
        
        // 直接使用包名集合
       val whitelistPackages = whitelistJson

        Log.d(TAG, "Whitelisted apps: $whitelistPackages")
        
        val isAllowed = whitelistPackages.contains(foregroundPackage)
        Log.d(TAG, "App $foregroundPackage ${if (isAllowed) "is in the whitelist" else "is not in the whitelist"}")
        
        return isAllowed
    }
    
    private fun handleTapGesture(tapCount: Int) {
        Log.d(TAG, "Handling $tapCount-tap gesture")
        
        // 检查应用白名单
        if (!isAppInWhitelist()) {
            Log.d(TAG, "Current app is not in the whitelist, ignoring gesture")
            return
        }
        
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val actionKey = when (tapCount) {
            2 -> PREF_GESTURE_TAP_2_ACTION
            3 -> PREF_GESTURE_TAP_3_ACTION
            else -> return
        }

        val actionIndex = prefs.getInt(actionKey, if (tapCount == 2) 0 else 2)
        Log.d(TAG, "Configured action index: $actionIndex")

        val launchIntent = when (actionIndex) {
            0 -> QuickActionActivity.createIntent(
                this,
                QuickActionActivity.ACTION_TEMPLATES
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            1 -> {
                Log.d(TAG, "Triggering quick summary save")
                Intent(this, QuickSaveActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    action = "QUICK_SAVE_FROM_NOTIFICATION"
                }
            }

            2 -> QuickActionActivity.createIntent(
                this,
                QuickActionActivity.ACTION_SUMMARIES
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            else -> null
        }

        if (launchIntent == null) {
            Log.w(TAG, "Unrecognized action index: $actionIndex")
            return
        }

        startActivity(launchIntent)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
        isServiceRunning = false
        Log.d(TAG, "========== FloatingWindowService stopped ==========")
    }
}
