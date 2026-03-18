package com.ironion.localvault

import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * 模板快捷方式服务
 */
@RequiresApi(Build.VERSION_CODES.N)
class TemplateTileService : BaseTileService() {

    companion object {
        private const val TAG = "TemplateTileService"
    }

    override fun getTileLabel(): String = "摘要模板"

    override fun getLaunchIntent(): Intent {
        return QuickActionActivity.createIntent(this, QuickActionActivity.ACTION_TEMPLATES)
    }
}
