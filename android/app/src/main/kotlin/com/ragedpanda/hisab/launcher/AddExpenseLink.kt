package com.ragedpanda.hisab.launcher

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.ragedpanda.hisab.MainActivity

/**
 * The editor for a new expense, straight away: hisab://entry?kind=expense is
 * what the static "Add expense" launcher shortcut opens too, and the editor
 * focuses the amount (keypad up) for a new entry.
 */
object AddExpenseLink {
    private const val LINK = "hisab://entry?kind=expense"

    fun intent(context: Context): Intent =
        Intent(Intent.ACTION_VIEW, Uri.parse(LINK), context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

    fun pendingIntent(context: Context, requestCode: Int): PendingIntent =
        PendingIntent.getActivity(context, requestCode, intent(context), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}
