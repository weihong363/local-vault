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

        Log.d(TAG, "=== QuickSaveActivity created ===")
        
        // 检查 Intent 来源
        val action = intent?.action
        Log.d(TAG, "Intent action: $action")
        
        if (action == "QUICK_SAVE_FROM_TILE" || action == "QUICK_SAVE_FROM_NOTIFICATION") {
            // 来自磁贴或通知的触发
            pendingClipboardRead = true
            Log.d(TAG, "Set to pending clipboard read mode")
        } else {
            Log.w(TAG, "Unknown trigger source, closing activity")
            finish()
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        Log.d(TAG, "=== QuickSaveActivity warm start ===")
        
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

            Log.d(TAG, "✅ Window gained focus, reading the clipboard and saving...")
            
          try {
                // 读取剪贴板
                val clipboardText = readClipboard()
                
                if (clipboardText != null && clipboardText.isNotEmpty()) {
                    Log.d(TAG, "✅ Clipboard read succeeded, length: ${clipboardText.length}")
                    
                    // 通过 MethodChannel 调用 Flutter 端保存（如果 Flutter 已启动）
                    // 或者显示通知让用户手动保存
                    saveToDatabase(clipboardText)
                    
                    // 显示成功提示
                    showSuccessToast()
                } else {
                    Log.w(TAG, "⚠️ Clipboard is empty")
                    showEmptyClipboardToast()
                }
                
            } catch (e: Exception) {
              Log.e(TAG, "❌ Failed to read or save", e)
                showErrorToast(e.message)
            } finally {
                // 完成后关闭 Activity
              Log.d(TAG, "Task finished, closing activity")
                finish()
            }
        }
    }
    
    /**
     * 读取剪贴板内容
     */
  private fun readClipboard(): String? {
        Log.d(TAG, "📋 Reading clipboard...")
        
      try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            
            if (!clipboard.hasPrimaryClip()) {
                Log.w(TAG, "Clipboard has no content")
                return null
            }
            
            val clipData = clipboard.primaryClip
            if (clipData != null && clipData.itemCount > 0) {
                val item = clipData.getItemAt(0)
                val text = item.text?.toString()
                
                if (text != null) {
                    Log.d(TAG, "📋 Read succeeded, length=${text.length}")
                    Log.d(TAG, "📋 Content preview: ${text.take(100)}${if (text.length > 100) "..." else ""}")
                    return text
                }
            }

          Log.w(TAG, "Clipboard content is empty")
            return null
            
        } catch (e: Exception) {
          Log.e(TAG, "Failed to read clipboard", e)
            throw e
        }
    }
    
    /**
     * 保存到数据库
     * 方案：通过 local_vault/share channel 发送请求，让 MainActivity 统一处理
     */
 private fun saveToDatabase(content: String) {
        Log.d(TAG, "💾 Saving to the database...")
  
 try {
    // 使用 MainActivity 中保存的静态 FlutterEngine 引用
   MainActivity.flutterEngine?.let { engine ->
       Log.d(TAG, "✅ Flutter engine is ready, saving via share channel")

       // ✅ 关键修复：使用 local_vault/share channel 而不是 quick_save channel
       // 这样可以让 ShareService 统一处理，避免 Flutter 未就绪的问题
       val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "local_vault/share")

       // 调用 onQuickSaveRequested 方法，让 ShareService 处理
       channel.invokeMethod("onQuickSaveRequested", content, object : MethodChannel.Result {
  override fun success(result: Any?) {
      Log.d(TAG, "✅ ShareService received the request")
  }
  
  override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      Log.e(TAG, "❌ ShareService failed: $errorCode - $errorMessage")
      // 降级方案：显示通知
      showFallbackNotification(content)
  }
  
  override fun notImplemented() {
      Log.w(TAG, "⚠️ ShareService not implemented; app may not be fully started yet")
  // 显示降级通知，引导用户手动打开应用
  showFallbackNotification(content)
  }
})
 } ?: run {
       Log.w(TAG, "⚠️ Flutter engine is not running, cannot save directly")
       // Flutter 未启动时，显示降级通知
       showFallbackNotification(content)
 }
 
 } catch (e: Exception) {
     Log.e(TAG, "Failed to save to the database", e)
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
            Log.d(TAG, "Displayed success toast")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display success toast", e)
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
            Log.d(TAG, "Displayed empty clipboard toast")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display empty clipboard toast", e)
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
            Log.d(TAG, "Displayed error toast")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display error toast", e)
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
      Log.d(TAG, "Displayed fallback notification, temp file: ${tempFile.absolutePath}")
   
  } catch (e: Exception) {
      Log.e(TAG, "Failed to display fallback notification", e)
  }
 }
}
