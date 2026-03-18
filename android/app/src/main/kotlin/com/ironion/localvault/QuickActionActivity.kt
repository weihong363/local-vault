package com.ironion.localvault

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 快捷操作 Activity - 用于模板和摘要选择
 * 透明主题，不会显示主应用窗口
 */
class QuickActionActivity : FlutterActivity() {
    companion object {
        private const val TAG = "QuickActionActivity"
        private const val CHANNEL = "com.ironion.localvault/quick_action"
        private const val PERMISSIONS_CHANNEL = "local_vault/permissions"
        private const val EXTRA_ACTION_TYPE = "action_type"

        const val ACTION_TEMPLATES = "OPEN_TEMPLATES"
        const val ACTION_SUMMARIES = "OPEN_SUMMARIES"

        /**
         * 创建启动 Intent
         */
        fun createIntent(context: Context, actionType: String): Intent {
            return Intent(context, QuickActionActivity::class.java).apply {
                putExtra(EXTRA_ACTION_TYPE, actionType)
            }
        }
    }

    private var actionType: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "QuickActionActivity onCreate")

        // 设置窗口属性，消除黑色背景
        window?.apply {
            // 设置透明背景
            setBackgroundDrawableResource(android.R.color.transparent)
            decorView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
            
            // 设置窗口大小为 WRAP_CONTENT
            setLayout(
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT
            )
            
            // 设置窗口为半透明
            setFlags(
                android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                        android.view.WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                        android.view.WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            )
            
            // 清除默认的 dim 效果
            clearFlags(android.view.WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            
            // 设置软输入模式
            setSoftInputMode(
                android.view.WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or
                        android.view.WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN
            )
        }
        
        actionType = intent.getStringExtra(EXTRA_ACTION_TYPE)
        Log.d(TAG, "Action type: $actionType")
    }
    
    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        Log.d(TAG, "onAttachedToWindow")
        
        // 再次确保窗口属性正确
        window?.apply {
            setBackgroundDrawableResource(android.R.color.transparent)
            decorView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
            setLayout(
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
                android.view.ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            Log.d(TAG, "onWindowFocusChanged - 窗口获得焦点，重新设置窗口属性")
            window?.apply {
                setBackgroundDrawableResource(android.R.color.transparent)
                decorView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
                setLayout(
                    android.view.ViewGroup.LayoutParams.WRAP_CONTENT,
                    android.view.ViewGroup.LayoutParams.WRAP_CONTENT
                )
            }
        }
    }

    override fun getInitialRoute(): String {
        return "/quick-action-activity"
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configuring Flutter engine")

        // 保存 FlutterEngine 引用供其他 Activity 使用
        MainActivity.flutterEngine = flutterEngine

        // 设置 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "finishActivity" -> {
                    Log.d(TAG, "收到 finishActivity 请求")
                    finish()
                    result.success(null)
                }
                "getActionType" -> {
                    Log.d(TAG, "收到 getActionType 请求，返回: $actionType")
                    result.success(actionType)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PERMISSIONS_CHANNEL
        ).setMethodCallHandler { call, result ->
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
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "QuickActionActivity onDestroy")
    }

    private fun hasUsageStatsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val usageStatsManager =
                getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60,
                time
            )
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
                Log.w(TAG, "Usage Access 设置页不可用，降级跳转到系统设置")
                startActivity(fallbackIntent)
            }

            else -> {
                Log.e(TAG, "无法打开任何系统设置页面")
            }
        }
    }
}
