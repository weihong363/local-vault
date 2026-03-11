package com.ironion.localvault

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

    override fun getTileLabel(): String = "我的记忆"

    override fun getLaunchIntent(): Intent {
        return QuickActionActivity.createIntent(this, QuickActionActivity.ACTION_SUMMARIES)
    }
}
