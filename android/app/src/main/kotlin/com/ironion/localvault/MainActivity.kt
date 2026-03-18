package com.ironion.localvault

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Parcelable
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
    private val MODEL_ASSET_CHANNEL = "local_vault/model_assets"
  private val APPS_CHANNEL = "local_vault/apps"
  private val QUICK_ACTION_CHANNEL = "com.ironion.localvault/quick_action"
  private var pendingAction: String? = null
  private var pendingShareText: String? = null
  private var whitelistPackages = mutableSetOf<String>()
  
 companion object {
     // 保存 FlutterEngine 的静态引用，供 QuickSaveActivity 和 QuickActionActivity 使用
    var flutterEngine: FlutterEngine? = null
     private var slmNativeLibraryLoaded: Boolean = false
 }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let { intent ->
            val action = intent.action
            val mimeType = intent.type

            when (action) {
                Intent.ACTION_SEND -> {
                    when {
                        // 处理文本分享
                        mimeType == "text/plain" -> {
                            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                            if (text != null) {
                                pendingShareText = text
                                Log.d(
                                    TAG,
                                    "Received shared text: ${text.take(100)}${if (text.length > 100) "..." else ""}"
                                )
                                notifyFlutterOfShare(text)
                            } else {
                                Log.w(TAG, "Received text-share intent but EXTRA_TEXT was null")
                            }
                        }
                        // 处理图片分享
                        mimeType?.startsWith("image/") == true -> {
                            val imageUri = intent.getParcelableExtraCompat<Uri>(Intent.EXTRA_STREAM)
                            if (imageUri != null) {
                                pendingShareImageUri = imageUri.toString()
                                Log.d(TAG, "Received single shared image: $imageUri")
                                shareChannel?.invokeMethod("onImageReceived", mapOf(
                                    "uri" to imageUri.toString(),
                                    "type" to "single"
                                ))
                            } else {
                                Log.w(TAG, "Received image-share intent but EXTRA_STREAM was null")
                            }
                        }
                        else -> {
                            Log.w(TAG, "Received unsupported share type: $mimeType")
                        }
                    }
                }
                Intent.ACTION_SEND_MULTIPLE -> {
                    when {
                        // 处理多个文本分享
                        mimeType?.startsWith("text/") == true -> {
                            val uris = intent.getParcelableArrayListExtraCompat<Uri>(Intent.EXTRA_STREAM)
                            uris?.let { uriList ->
                                if (uriList.isNotEmpty()) {
                                    pendingShareText = uriList.joinToString("\n") { uri -> uri.toString() }
                                    Log.d(TAG, "Received multiple shared text items: ${uriList.size}")
                                    notifyFlutterOfShare(pendingShareText!!)
                                } else {
                                    Log.w(TAG, "Received multiple text-share intent but the list was empty")
                                }
                            } ?: run {
                                Log.w(TAG, "Received multiple text-share intent but EXTRA_STREAM was null")
                            }
                        }
                        // 处理多张图片分享
                        mimeType?.startsWith("image/") == true -> {
                            val uris = intent.getParcelableArrayListExtraCompat<Uri>(Intent.EXTRA_STREAM)
                            uris?.let { uriList ->
                                val uriStrings = uriList.map { uri -> uri.toString() }
                                pendingShareImageUri = uriStrings.firstOrNull()
                                Log.d(TAG, "Received multiple shared images: ${uriStrings.size}")
                                shareChannel?.invokeMethod("onImageReceived", mapOf(
                                    "uris" to uriStrings,
                                    "type" to "multiple"
                                ))
                            } ?: run {
                                Log.w(TAG, "Received multiple image-share intent but EXTRA_STREAM was null")
                            }
                        }
                        else -> {
                            Log.w(TAG, "Received unsupported multi-share type: $mimeType")
                        }
                    }
                }
                "OPEN_TEMPLATES", "OPEN_SUMMARIES", "OPEN_INJECT" -> {
               pendingAction = action
                    Log.d(TAG, "Received pending action: $action")
            }
           "QUICK_SAVE" -> {
               // 快速保存 - 从剪贴板读取内容
               Log.d(TAG, "Received quick save request")
              handleQuickSave()
            }
            "QUICK_SAVE_FROM_TILE" -> {
                // 从控制中心快捷开关触发的快速保存
                Log.d(TAG, "Received Quick Settings quick save request")
               // 直接从剪贴板读取内容
             handleQuickSave()
            }
          else -> {
              Log.d(TAG, "Received unknown intent: action=$action, type=$mimeType")
            }
            }
        }
    }

    @Suppress("DEPRECATION")
    private inline fun <reified T> Intent.getParcelableExtraCompat(key: String): T? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(key, T::class.java)
        } else {
            getParcelableExtra(key)
        }
    }

    @Suppress("DEPRECATION")
    private inline fun <reified T> Intent.getParcelableArrayListExtraCompat(key: String): ArrayList<T>? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableArrayListExtra(key, T::class.java)
        } else {
            getParcelableArrayListExtra<Parcelable>(key) as? ArrayList<T>
        }
    }

    private var shareChannel: MethodChannel? = null
    private var pendingShareImageUri: String? = null // 存储图片 URI
    
    private fun notifyFlutterOfShare(text: String) {
        shareChannel?.invokeMethod("onShareReceived", text)
    }

   /**
     * 处理快速保存请求
     * 从剪贴板读取内容并触发保存流程
     */
  private fun handleQuickSave() {
   try {
       Log.d(TAG, "=== Starting quick save handling ===")
     val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
     val clipData = clipboard.primaryClip
    
   if (clipData != null && clipData.itemCount > 0) {
       val text = clipData.getItemAt(0).text
      if (text != null) {
          Log.d(TAG, "✅ Read clipboard content, length: ${text.length}")
          Log.d(TAG, "📋 Content preview: ${text.take(100)}${if (text.length > 100) "..." else ""}")
         // 通知 Flutter 处理快捷保存
          Log.d(TAG, "📤 Calling shareChannel.invokeMethod...")
       shareChannel?.invokeMethod("onQuickSaveRequested", text.toString())
          Log.d(TAG, "✅ Flutter notified successfully")
      return
       }
    }
    
   // 如果剪贴板为空，通知 Flutter 显示输入框
       Log.d(TAG, "⚠️ Clipboard is empty, requesting input UI")
   shareChannel?.invokeMethod("onQuickSaveRequested", null)
 } catch (e: Exception) {
       Log.e(TAG, "❌ Failed to handle quick save", e)
   shareChannel?.invokeMethod("onQuickSaveRequested", null)
 }
}

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        loadSlmNativeLibraryIfAvailable()
        MainActivity.flutterEngine = flutterEngine
        
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
                "isFloatingServiceRunning" -> {
                    result.success(FloatingWindowService.isServiceRunning)
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
                "getTapGestureConfig" -> {
                    val tapCount = call.argument<Int>("tapCount")
                    if (tapCount != null) {
                        result.success(getTapGestureConfig(tapCount))
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing tapCount", null)
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
                                Log.d(TAG, "Read content URI into cache successfully: ${cacheFile.absolutePath}")
                                result.success(cacheFile.absolutePath)
                            } else {
                                Log.e(TAG, "Unable to read content URI: $uriString")
                                result.error("READ_ERROR", "无法读取 content URI", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to read content URI: ${e.message}", e)
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MODEL_ASSET_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyBundledModelToFiles" -> {
                    val assetPath = call.argument<String>("assetPath")
                    val fileName = call.argument<String>("fileName")
                    val targetPath = call.argument<String>("targetPath")

                    if (assetPath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "Missing assetPath or fileName", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val copiedFile = copyModelAssetToFiles(assetPath, fileName, targetPath)
                        result.success(copiedFile.absolutePath)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to copy model asset: ${e.message}", e)
                        result.error("MODEL_COPY_FAILED", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val installedApps = getInstalledApps()
                        result.success(installedApps)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get installed apps", e)
                        result.error("GET_APPS_FAILED", e.message, null)
                    }
                }
                "setWhitelist" -> {
                    try {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        whitelistPackages.clear()
                        whitelistPackages.addAll(packages)
                        PreferenceManager.getDefaultSharedPreferences(this)
                            .edit()
                            .putStringSet("app_whitelist", packages.toSet())
                            .apply()
                        Log.d(TAG, "Updated app whitelist: $whitelistPackages")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to update app whitelist", e)
                        result.error("SET_WHITELIST_FAILED", e.message, null)
                    }
                }

                "getWhitelistPackages" -> {
                    try {
                        val packages = PreferenceManager.getDefaultSharedPreferences(this)
                            .getStringSet("app_whitelist", emptySet())
                            ?.toList()
                            ?.sorted()
                            ?: emptyList()
                        result.success(packages)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get app whitelist", e)
                        result.error("GET_WHITELIST_FAILED", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QUICK_ACTION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "finishActivity" -> {
                    Log.d(TAG, "Received finishActivity request, closing activity")
                    finish()
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

    private fun loadSlmNativeLibraryIfAvailable() {
        if (slmNativeLibraryLoaded) {
            return
        }

        try {
            System.loadLibrary("llm_inference_engine")
            slmNativeLibraryLoaded = true
            Log.i(TAG, "SLM native library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "SLM native library unavailable, fallback mode will be used: ${e.message}")
        } catch (e: SecurityException) {
            Log.w(TAG, "SLM native library load blocked: ${e.message}")
        }
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

    private fun getTapGestureConfig(tapCount: Int): Int {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val tapKey = when (tapCount) {
            2 -> "gesture_tap_2_action"
            3 -> "gesture_tap_3_action"
            else -> return -1
        }

        return prefs.getInt(tapKey, if (tapCount == 2) 0 else 2)
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
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) {
            return
        }

        val usageAccessIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        val fallbackIntent = Intent(Settings.ACTION_SETTINGS)

        when {
            usageAccessIntent.resolveActivity(packageManager) != null -> {
                startActivity(usageAccessIntent)
            }

            fallbackIntent.resolveActivity(packageManager) != null -> {
                Log.w(TAG, "Usage Access settings page is unavailable, falling back to system settings")
                startActivity(fallbackIntent)
            }

            else -> {
                Log.e(TAG, "Unable to open any system settings page")
            }
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

    private fun copyModelAssetToFiles(assetPath: String, fileName: String, targetPath: String?): File {
        val targetFile = if (!targetPath.isNullOrBlank()) {
            File(targetPath)
        } else {
            File(File(filesDir, "models"), fileName)
        }

        targetFile.parentFile?.mkdirs()
        if (targetFile.exists() && targetFile.length() > 0L) {
            return targetFile
        }

        assets.open(assetPath).use { input ->
            FileOutputStream(targetFile).use { output ->
                input.copyTo(output)
            }
        }
        return targetFile
    }

    /**
     * 启动悬浮窗服务
     * 注意：FloatingWindowService 必须在 onCreate 中调用 startForeground() 以避免被系统杀死
     */
    private fun startFloatingService() {
        // 检查悬浮窗权限
        if (!hasOverlayPermission()) {
            Log.w(TAG, "Missing overlay permission, requesting access")
            requestOverlayPermission()
            return
        }

        // 避免重复启动
        if (FloatingWindowService.isServiceRunning) {
            Log.d(TAG, "Floating window service is already running")
            return
        }

        // 根据 Android 版本选择启动方式
        val serviceIntent = Intent(this, FloatingWindowService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Log.d(TAG, "Starting foreground service (Android O+)")
                startForegroundService(serviceIntent)
            } else {
                Log.d(TAG, "Starting background service (Android < O)")
                startService(serviceIntent)
            }
            Log.i(TAG, "Floating window service start request sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start floating window service: ${e.message}", e)
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
            Log.d(TAG, "Content URI MIME type: $mimeType")
            
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

            Log.d(TAG, "Preparing to save file: $fileName, MIME: $mimeType")
            
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
                Log.d(TAG, "Called fd.sync() to ensure data was flushed to disk")
            }
            
            output.close()
            input.close()

            Log.d(TAG, "Copied $totalBytes bytes to the cache file successfully: $fileName")
            Log.d(TAG, "Cache file path: ${cacheFile.absolutePath}")
            Log.d(TAG, "Cache file size: ${cacheFile.length()} bytes")
            
            // 验证文件是否正确写入
            if (!cacheFile.exists() || cacheFile.length() == 0L) {
                Log.e(TAG, "Cache file is empty or missing")
                return null
            }
            
            // 验证文件大小是否匹配（如果输入流支持 mark/reset）
            if (totalBytes == 0L) {
                Log.e(TAG, "Copied byte count was 0")
                return null
            }
            
            // 读取文件头几个字节检查是否是有效的 PNG/JPG 格式
            val fileHeader = readImageHeader(cacheFile)
            Log.d(TAG, "File header check: $fileHeader")
            
            // 验证图片是否可以被 BitmapFactory 解码
            val options = android.graphics.BitmapFactory.Options()
            options.inJustDecodeBounds = true
            android.graphics.BitmapFactory.decodeFile(cacheFile.absolutePath, options)
            
            if (options.outWidth > 0 && options.outHeight > 0) {
                Log.d(TAG, "Image decode succeeded: ${options.outWidth}x${options.outHeight}")
            } else {
                Log.e(TAG, "Image decode failed! Width: ${options.outWidth}, height: ${options.outHeight}")
                Log.e(TAG, "File header: $fileHeader")
                Log.w(TAG, "Returning the file path anyway so ML Kit can still try")
            }
            
            cacheFile
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy content URI: ${e.message}", e)
            null
        } finally {
            try {
                input?.close()
                output?.close()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to close stream: ${e.message}")
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

    /**
     * 停止悬浮窗服务
     * 注意：isServiceRunning 状态可能在检查后发生变化，实际停止是异步的
     */
   private fun stopFloatingService() {
       if (!FloatingWindowService.isServiceRunning) {
           Log.d(TAG, "Floating window service is not running")
            return
        }
        
       val serviceIntent = Intent(this, FloatingWindowService::class.java)
        try {
            stopService(serviceIntent)
            Log.i(TAG, "Floating window service stop request sent")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop floating window service: ${e.message}", e)
        }
    }

    /**
     * 获取已安装的应用列表
     */
    private fun getInstalledApps(): List<Map<String, String>> {
        val apps = mutableListOf<Map<String, String>>()
        val packageManager = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = packageManager.queryIntentActivities(intent, 0)

        for (resolveInfo in resolveInfos) {
            val appName = resolveInfo.loadLabel(packageManager).toString()
            val packageName = resolveInfo.activityInfo.packageName
            
            apps.add(
                mapOf(
                    "packageName" to packageName,
                    "appName" to appName
                )
            )
        }

        // 按应用名称排序
        apps.sortBy { it["appName"] }
        return apps
    }
}
