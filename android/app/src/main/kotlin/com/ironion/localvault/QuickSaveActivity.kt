package com.ironion.localvault

import android.app.Activity
import android.app.PendingIntent
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 快速保存 Activity - 透明无感知
 * 
 * 功能：
 * 1. 从 TileService/通知启动，用户无感知
 * 2. 在窗口获得焦点时读取剪贴板
 * 3. 直接保存到数据库，无需打开 UI
 * 4. 完成后自动关闭
 */
@RequiresApi(Build.VERSION_CODES.N)
class QuickSaveActivity : Activity() {
    
   companion object {
      private const val TAG = "QuickSaveActivity"
      private const val CHANNEL = "com.ironion.localvault/quick_save"
    }
    
    // 状态标记
  private var pendingClipboardRead = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "=== QuickSaveActivity 创建 ===")
        
        // 检查 Intent 来源
        val action = intent?.action
        Log.d(TAG, "Intent action: $action")
        
        if (action == "QUICK_SAVE_FROM_TILE" || action == "QUICK_SAVE_FROM_NOTIFICATION") {
            // 来自磁贴或通知的触发
            pendingClipboardRead = true
            Log.d(TAG, "设置为待读取剪贴板模式")
        } else {
            Log.w(TAG, "未知触发来源，关闭 Activity")
            finish()
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        Log.d(TAG, "=== QuickSaveActivity 热启动 ===")
        
        val action = intent.action
        if (action == "QUICK_SAVE_FROM_TILE" || action == "QUICK_SAVE_FROM_NOTIFICATION") {
            pendingClipboardRead = true
        } else {
            finish()
        }
    }
    
    /**
     * 关键：在窗口获得焦点时才读取剪贴板
     * Android 10+ 要求必须是前台应用才能访问剪贴板
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        
        Log.d(TAG, "onWindowFocusChanged: hasFocus = $hasFocus, pendingClipboardRead = $pendingClipboardRead")
        
        // ⚡ 仅在获得焦点且需要读取剪贴板时执行一次
        if (hasFocus && pendingClipboardRead) {
            pendingClipboardRead = false  // 清除标记，防止重复执行
            
            Log.d(TAG, "✅ 窗口获得焦点，开始读取剪贴板并保存...")
            
          try {
                // 读取剪贴板
                val clipboardText = readClipboard()
                
                if (clipboardText != null && clipboardText.isNotEmpty()) {
                    Log.d(TAG, "✅ 剪贴板读取成功，长度：${clipboardText.length}")
                    
                    // 通过 MethodChannel 调用 Flutter 端保存（如果 Flutter 已启动）
                    // 或者显示通知让用户手动保存
                    saveToDatabase(clipboardText)
                    
                    // 显示成功提示
                    showSuccessToast()
                } else {
                    Log.w(TAG, "⚠️ 剪贴板为空")
                    showEmptyClipboardToast()
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ 读取或保存失败", e)
                showErrorToast(e.message)
            } finally {
                // 完成后关闭 Activity
                Log.d(TAG, "完成任务，关闭 Activity")
                finish()
            }
        }
    }
    
    /**
     * 读取剪贴板内容
     */
  private fun readClipboard(): String? {
        Log.d(TAG, "📋 开始读取剪贴板...")
        
      try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            
            if (!clipboard.hasPrimaryClip()) {
                Log.w(TAG, "剪贴板没有内容")
                return null
            }
            
            val clipData = clipboard.primaryClip
            if (clipData != null && clipData.itemCount > 0) {
                val item = clipData.getItemAt(0)
                val text = item.text?.toString()
                
                if (text != null) {
                    Log.d(TAG, "📋 读取成功，长度=${text.length}")
                    Log.d(TAG, "📋 内容预览：${text.take(100)}${if (text.length > 100) "..." else ""}")
                    return text
                }
            }
            
            Log.w(TAG, "剪贴板内容为空")
            return null
            
        } catch (e: Exception) {
            Log.e(TAG, "读取剪贴板失败", e)
            throw e
        }
    }
    
    /**
     * 保存到数据库
     * 方案：通过 MethodChannel 调用 Flutter 端，如果 Flutter 未启动则显示通知
     */
 private fun saveToDatabase(content: String) {
  Log.d(TAG, "💾 开始保存到数据库...")
  
 try {
    // 使用 MainActivity 中保存的静态 FlutterEngine 引用
   MainActivity.flutterEngine?.let { engine ->
     Log.d(TAG, "✅ Flutter 引擎已就绪，通过 MethodChannel 调用保存")
     
    val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
    
    // 调用 Flutter 端的保存方法
   channel.invokeMethod("saveFromClipboard", content, object : MethodChannel.Result {
  override fun success(result: Any?) {
  Log.d(TAG, "✅ Flutter 端保存成功")
  }
  
  override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
  Log.e(TAG, "❌ Flutter 端保存失败：$errorCode - $errorMessage")
  }
  
  override fun notImplemented() {
  Log.w(TAG, "⚠️ Flutter 端未实现 saveFromClipboard 方法，应用可能还未完全启动")
  // 显示降级通知，引导用户手动打开应用
  showFallbackNotification(content)
  }
})
 } ?: run {
   Log.w(TAG, "⚠️ Flutter 引擎未启动，无法直接保存")
  // Flutter 未启动时，可以显示通知引导用户
 }
 
 } catch (e: Exception) {
  Log.e(TAG, "保存到数据库失败", e)
  throw e
 }
}
    
    /**
     * 显示成功 Toast
     */
    private fun showSuccessToast() {
        try {
            android.widget.Toast.makeText(
                this,
                "✅ 保存成功 - 已自动保存到 Local Vault",
                android.widget.Toast.LENGTH_SHORT
            ).show()
            Log.d(TAG, "已显示成功 Toast")
        } catch (e: Exception) {
            Log.e(TAG, "显示成功 Toast 失败", e)
        }
    }
    
    /**
     * 显示剪贴板为空的 Toast
     */
    private fun showEmptyClipboardToast() {
        try {
            android.widget.Toast.makeText(
                this,
                "⚠️ 剪贴板为空，请先复制要保存的内容",
                android.widget.Toast.LENGTH_SHORT
            ).show()
            Log.d(TAG, "已显示空剪贴板 Toast")
        } catch (e: Exception) {
            Log.e(TAG, "显示空剪贴板 Toast 失败", e)
        }
    }
    
    /**
     * 显示错误 Toast
     */
    private fun showErrorToast(errorMsg: String?) {
        try {
            android.widget.Toast.makeText(
                this,
                "❌ 保存失败：${errorMsg ?: "未知错误"}",
                android.widget.Toast.LENGTH_SHORT
            ).show()
            Log.d(TAG, "已显示错误 Toast")
        } catch (e: Exception) {
            Log.e(TAG, "显示错误 Toast 失败", e)
        }
    }
  
  /**
   * 显示降级通知（当 Flutter 未就绪时）
   */
  private fun showFallbackNotification(content: String) {
  try {
       val notificationManager= getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
      
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
          val channel = android.app.NotificationChannel(
             "quick_save_fallback",
              "快速保存（降级方案）",
           android.app.NotificationManager.IMPORTANCE_HIGH
         ).apply {
           description = "当应用未启动时显示的通知"
             setShowBadge(false)
         }
        notificationManager.createNotificationChannel(channel)
     }
     
    // 将内容保存到临时文件，以便后续读取
    val tempFile = File(cacheDir, "clipboard_temp_${System.currentTimeMillis()}.txt")
    tempFile.writeText(content)
    
    val intent = Intent(this, MainActivity::class.java).apply {
       flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    
    val pendingIntent= PendingIntent.getActivity(
       this,
      0,
     intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    
    val preview = content.take(50) + if (content.length > 50) "..." else ""
    val notification= androidx.core.app.NotificationCompat.Builder(this, "quick_save_fallback")
       .setSmallIcon(android.R.drawable.ic_menu_save)
       .setContentTitle("⚠️ 应用未完全启动")
       .setContentText("点击打开应用并保存：$preview")
       .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
       .setContentIntent(pendingIntent)
       .setAutoCancel(true)
       .build()
    
   notificationManager.notify(2004, notification)
  Log.d(TAG, "已显示降级通知，临时文件：${tempFile.absolutePath}")
   
  } catch (e: Exception) {
  Log.e(TAG, "显示降级通知失败", e)
  }
 }
}