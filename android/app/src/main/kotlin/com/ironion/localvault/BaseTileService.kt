package com.ironion.localvault

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat

/**
 * 快捷方式基类 - 减少重复代码
 */
@RequiresApi(Build.VERSION_CODES.N)
abstract class BaseTileService : TileService() {

    companion object {
        private const val CHANNEL_ID = "quick_action_channel"
        private const val NOTIFICATION_ID_BASE = 2000
    }

    /**
     * 获取快捷方式的标签
     */
    abstract fun getTileLabel(): String

    /**
     * 获取启动的 Intent
     */
    abstract fun getLaunchIntent(): Intent

    override fun onClick() {
        super.onClick()
        android.util.Log.d(getTileLabel(), "Quick Settings tile tapped")
        launchActivity()
    }

    /**
     * 启动对应的 Activity
     */
    private fun launchActivity() {
        try {
            android.util.Log.d(getTileLabel(), "Attempting to launch activity...")

            val intent = getLaunchIntent()
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            startActivityAndCollapse(pendingIntent)
            android.util.Log.i(getTileLabel(), "Activity launched successfully")

        } catch (e: Exception) {
            android.util.Log.e(getTileLabel(), "Launch failed, falling back to a notification", e)
            sendFallbackNotification()
        }
    }

    /**
     * 发送回退通知
     */
    private fun sendFallbackNotification() {
        try {
            createNotificationChannel()

            val intent = getLaunchIntent()
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_menu_save)
                .setContentTitle("⚡ ${getTileLabel()}")
                .setContentText("点击打开")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .build()

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID_BASE + this.javaClass.simpleName.hashCode(), notification)

            android.util.Log.i(getTileLabel(), "Fallback notification sent")
        } catch (e: Exception) {
            android.util.Log.e(getTileLabel(), "Failed to send notification", e)
        }
    }

    /**
     * 创建通知渠道（Android 8.0+ 必需）
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "快捷操作",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "用于控制中心快捷操作功能"
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
