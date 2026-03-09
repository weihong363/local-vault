package com.ironion.local_vault

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.preference.PreferenceManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val FLOATING_CHANNEL = "local_vault/floating_window"
    private val GESTURE_CONFIG_CHANNEL = "local_vault/gesture_config"
    private val PERMISSIONS_CHANNEL = "local_vault/permissions"
    private val SHARE_CHANNEL = "local_vault/share"
    private var pendingAction: String? = null
    private var pendingShareText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            when (it.action) {
                Intent.ACTION_SEND -> {
                    when {
                        // 处理文本分享
                        it.type == "text/plain" -> {
                            val text = it.getStringExtra(Intent.EXTRA_TEXT)
                            if (text != null) {
                                pendingShareText = text
                                Log.d(TAG, "收到分享内容：$text")
                                notifyFlutterOfShare(text)
                            }
                        }
                        // 处理图片分享
                        it.type?.startsWith("image/") == true -> {
                            val imageUri = it.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                            if (imageUri != null) {
                                pendingShareImageUri = imageUri.toString()
                                Log.d(TAG, "收到图片分享：$imageUri")
                                // 通知 Flutter 有图片需要 OCR
                                shareChannel?.invokeMethod("onImageReceived", mapOf(
                                    "uri" to imageUri.toString(),
                                    "type" to "single"
                                ))
                            }
                        }
                    }
                }
                Intent.ACTION_SEND_MULTIPLE -> {
                    when {
                        // 处理多个文本分享
                        it.type?.startsWith("text/") == true -> {
                            val uris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                it.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                it.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                            }
                            uris?.let { uriList ->
                                pendingShareText = uriList.joinToString("\n") { uri -> uri.toString() }
                                Log.d(TAG, "收到多个分享内容：$pendingShareText")
                                notifyFlutterOfShare(pendingShareText!!)
                            }
                        }
                        // 处理多张图片分享
                        it.type?.startsWith("image/") == true -> {
                            val uris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                it.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                it.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                            }
                            uris?.let { uriList ->
                                val uriStrings = uriList.map { uri -> uri.toString() }
                                pendingShareImageUri = uriStrings.firstOrNull()
                                Log.d(TAG, "收到多张图片分享：${uriStrings.size} 张")
                                // 通知 Flutter 有多张图片需要 OCR
                                shareChannel?.invokeMethod("onImageReceived", mapOf(
                                    "uris" to uriStrings,
                                    "type" to "multiple"
                                ))
                            }
                        }
                    }
                }
                "OPEN_TEMPLATES", "OPEN_SUMMARIES" -> {
                    pendingAction = it.action
                }
            }
        }
    }
    
    private var shareChannel: MethodChannel? = null
    private var pendingShareImageUri: String? = null // 存储图片 URI
    
    private fun notifyFlutterOfShare(text: String) {
        shareChannel?.invokeMethod("onShareReceived", text)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLOATING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startFloatingService" -> {
                    startFloatingService()
                    result.success(null)
                }
                "stopFloatingService" -> {
                    stopFloatingService()
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "getPendingAction" -> {
                    val action = pendingAction
                    pendingAction = null
                    result.success(action)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_CONFIG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setTapGestureConfig" -> {
                    val tapCount = call.argument<Int>("tapCount")
                    val actionIndex = call.argument<Int>("actionIndex")
                    
                    if (tapCount != null && actionIndex != null) {
                        saveTapGestureConfig(tapCount, actionIndex)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing arguments", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingShareText" -> {
                    val text = pendingShareText
                    pendingShareText = null
                    result.success(text)
                }
                "getPendingShareImageUri" -> {
                    val uri = pendingShareImageUri
                    pendingShareImageUri = null
                    result.success(uri)
                }
                "readContentUriToCache" -> {
                    // 读取 content URI 到缓存文件（废弃，保留兼容性）
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val cacheFile = copyContentUriToCache(uri)
                            if (cacheFile != null) {
                                Log.d(TAG, "成功读取 content URI 到缓存：${cacheFile.absolutePath}")
                                result.success(cacheFile.absolutePath)
                            } else {
                                Log.e(TAG, "无法读取 content URI: $uriString")
                                result.error("READ_ERROR", "无法读取 content URI", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "读取 content URI 失败：${e.message}", e)
                            result.error("READ_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Missing URI argument", null)
                    }
                }
                "performOcrOnContentUri" -> {
                    // 直接在原生端对 content URI 进行 OCR 识别（需要 ML Kit 依赖）
                    // 此方法暂时不使用，回退到 Flutter 端 OCR
                    result.error("NOT_IMPLEMENTED", "此方法需要额外的 ML Kit 依赖", null)
                }
                "reset" -> {
                    pendingShareText = null
                    pendingShareImageUri = null
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 保存 channel 引用，用于主动通知 Flutter
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
    }

    private fun saveTapGestureConfig(tapCount: Int, actionIndex: Int) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val editor = prefs.edit()
        
        val tapKey = when (tapCount) {
            2 -> "gesture_tap_2_action"
            3 -> "gesture_tap_3_action"
            else -> return
        }
        
        editor.putInt(tapKey, actionIndex)
        editor.apply()
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60,
                time
            )
            // 如果能查询到数据，说明有权限
            stats != null && stats.isNotEmpty()
        } else {
            true
        }
    }

    private fun requestUsageStatsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val intent = Intent(
                Settings.ACTION_USAGE_ACCESS_SETTINGS
            )
            startActivity(intent)
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, 1001)
        }
    }

    private fun startFloatingService() {
        if (!hasOverlayPermission()) {
            requestOverlayPermission()
            return
        }
        
        if (!FloatingWindowService.isServiceRunning) {
            val intent = Intent(this, FloatingWindowService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }

    /**
     * 将 content URI 的内容复制到缓存文件
     * @param uri content:// URI
     * @return 缓存文件，如果失败则返回 null
     */
    private fun copyContentUriToCache(uri: Uri): File? {
        var input: java.io.InputStream? = null
        var output: java.io.OutputStream? = null
        return try {
            // 打开输入流
            input = contentResolver.openInputStream(uri)
                ?: return null
            
            // 创建缓存文件
            val cacheDir = cacheDir
            
            // 尝试获取 MIME 类型
            val mimeType = contentResolver.getType(uri)
            Log.d(TAG, "Content URI 的 MIME 类型：$mimeType")
            
            // 根据 MIME 类型决定扩展名
            val extension = when (mimeType) {
                "image/jpeg", "image/jpg" -> "jpg"
                "image/png" -> "png"
                "image/webp" -> "webp"
                "image/gif" -> "gif"
                else -> "png" // 默认使用 png（因为分享图通常是 PNG）
            }
            
            val fileName = "ocr_${System.currentTimeMillis()}.$extension"
            val cacheFile = File(cacheDir, fileName)
            
            Log.d(TAG, "准备保存文件：$fileName, MIME: $mimeType")
            
            // 使用 BufferedInputStream 和 BufferedOutputStream 提高可靠性
            input = java.io.BufferedInputStream(input, 8192)
            output = java.io.BufferedOutputStream(cacheFile.outputStream(), 8192)
            
            // 手动复制数据，确保完整性
            val buffer = ByteArray(8192)
            var totalBytes = 0L
            var bytesRead: Int
            
            while (input.read(buffer).also { bytesRead = it } != -1) {
                output.write(buffer, 0, bytesRead)
                totalBytes += bytesRead
            }
            
            // 强制刷新输出缓冲区到磁盘
            output.flush()
            
            // 使用 FileDescriptor 确保数据完全写入存储
            if (output is java.io.FileOutputStream) {
                output.fd.sync()
                Log.d(TAG, "已调用 fd.sync() 确保数据写入磁盘")
            }
            
            output.close()
            input.close()
            
            Log.d(TAG, "成功复制 $totalBytes 字节到缓存文件：$fileName")
            Log.d(TAG, "缓存文件路径：${cacheFile.absolutePath}")
            Log.d(TAG, "缓存文件大小：${cacheFile.length()} 字节")
            
            // 验证文件是否正确写入
            if (!cacheFile.exists() || cacheFile.length() == 0L) {
                Log.e(TAG, "缓存文件为空或不存在")
                return null
            }
            
            // 验证文件大小是否匹配（如果输入流支持 mark/reset）
            if (totalBytes == 0L) {
                Log.e(TAG, "复制的字节数为 0")
                return null
            }
            
            // 读取文件头几个字节检查是否是有效的 PNG/JPG 格式
            val fileHeader = readImageHeader(cacheFile)
            Log.d(TAG, "文件头检查：$fileHeader")
            
            // 验证图片是否可以被 BitmapFactory 解码
            val options = android.graphics.BitmapFactory.Options()
            options.inJustDecodeBounds = true
            android.graphics.BitmapFactory.decodeFile(cacheFile.absolutePath, options)
            
            if (options.outWidth > 0 && options.outHeight > 0) {
                Log.d(TAG, "图片解码成功：${options.outWidth}x${options.outHeight}")
            } else {
                Log.e(TAG, "图片解码失败！宽：${options.outWidth}, 高：${options.outHeight}")
                Log.e(TAG, "文件头：$fileHeader")
                Log.w(TAG, "即使解码失败，也返回文件路径让 ML Kit 尝试")
            }
            
            cacheFile
        } catch (e: Exception) {
            Log.e(TAG, "复制 content URI 失败：${e.message}", e)
            null
        } finally {
            try {
                input?.close()
                output?.close()
            } catch (e: Exception) {
                Log.e(TAG, "关闭流失败：${e.message}")
            }
        }
    }
    
    /**
     * 读取图片文件头信息（用于调试）
     */
    private fun readImageHeader(file: File): String {
        return try {
            val input = java.io.FileInputStream(file)
            val header = ByteArray(16)
            val bytesRead = input.read(header)
            input.close()
            
            if (bytesRead >= 8) {
                val hexHeader = header.joinToString(" ") { "%02X".format(it) }
                // PNG 文件头应该是：89 50 4E 47 0D 0A 1A 0A
                // JPG 文件头应该是：FF D8 FF
                when {
                    header[0] == 0x89.toByte() && 
                    header[1] == 0x50.toByte() && 
                    header[2] == 0x4E.toByte() && 
                    header[3] == 0x47.toByte() -> "PNG (有效)"
                    header[0] == 0xFF.toByte() && 
                    header[1] == 0xD8.toByte() -> "JPG (有效)"
                    else -> "未知格式 (头：$hexHeader)"
                }
            } else {
                "文件太小，无法读取文件头"
            }
        } catch (e: Exception) {
            "读取文件头失败：${e.message}"
        }
    }

    private fun stopFloatingService() {
        if (FloatingWindowService.isServiceRunning) {
            val intent = Intent(this, FloatingWindowService::class.java)
            stopService(intent)
        }
    }
}
