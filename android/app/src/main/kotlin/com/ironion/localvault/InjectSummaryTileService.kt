package com.ironion.localvault

import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * 引用摘要快捷方式服务
 */
@RequiresApi(Build.VERSION_CODES.N)
class InjectSummaryTileService : BaseTileService() {

    companion object {
        private const val TAG = "InjectSummaryTileService"
    }

    override fun getTileLabel(): String = "引用摘要"

    override fun getLaunchIntent(): Intent {
        return Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = "OPEN_INJECT"
        }
    }
}
