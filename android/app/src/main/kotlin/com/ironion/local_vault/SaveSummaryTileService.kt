package com.ironion.local_vault

import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * 保存摘要快捷方式服务
 */
@RequiresApi(Build.VERSION_CODES.N)
class SaveSummaryTileService : BaseTileService() {

    companion object {
        private const val TAG = "SaveSummaryTileService"
    }

    override fun getTileLabel(): String = "保存摘要"

    override fun getLaunchIntent(): Intent {
        return Intent(this, QuickSaveActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = "QUICK_SAVE_FROM_TILE"
        }
    }
}
