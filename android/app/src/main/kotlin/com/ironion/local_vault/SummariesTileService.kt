package com.ironion.local_vault

import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * 本地记忆库快捷方式服务
 */
@RequiresApi(Build.VERSION_CODES.N)
class SummariesTileService : BaseTileService() {

    companion object {
        private const val TAG = "SummariesTileService"
    }

    override fun getTileLabel(): String = "本地记忆库"

    override fun getLaunchIntent(): Intent {
        return Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = "OPEN_SUMMARIES"
        }
    }
}
