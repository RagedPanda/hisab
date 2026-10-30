package com.ragedpanda.hisab.launcher

import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import com.ragedpanda.hisab.R

/** Asks the system to add the "Add expense" tile (Android 13+). */
object AddExpenseTileRequest {
    /** False when this Android cannot ask, so Dart explains the manual way. */
    fun request(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        val statusBar = context.getSystemService(StatusBarManager::class.java) ?: return false
        statusBar.requestAddTileService(
            ComponentName(context, AddExpenseTileService::class.java),
            context.getString(R.string.shortcut_add_expense),
            Icon.createWithResource(context, R.drawable.ic_tile_add_expense),
            context.mainExecutor,
        ) { /* Added, already there or dismissed: nothing to do either way. */ }
        return true
    }
}
