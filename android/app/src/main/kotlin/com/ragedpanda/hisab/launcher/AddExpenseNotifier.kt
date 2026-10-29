package com.ragedpanda.hisab.launcher

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.ragedpanda.hisab.R

/**
 * The opt-in persistent "Add expense" notification (Settings > Shortcuts &
 * widget, off by default). Dart hands over the on/off state and the text in
 * the user's language; it is kept here so [AddExpenseBootReceiver] can post
 * it again after a reboot or an app update.
 */
object AddExpenseNotifier {
    private const val CHANNEL_ID = "add_expense_shortcut"
    private const val NOTIFICATION_ID = 0xADD
    private const val PREFS = "hisab_add_expense_notification"

    fun configure(context: Context, arguments: Map<*, *>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean("enabled", arguments["enabled"] as? Boolean ?: false)
            .putString("channelName", arguments["channelName"] as? String)
            .putString("title", arguments["title"] as? String)
            .putString("body", arguments["body"] as? String)
            .apply()
        restore(context)
    }

    /** Posts the notification when it is on, removes it otherwise. */
    fun restore(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val manager = NotificationManagerCompat.from(context)
        if (!prefs.getBoolean("enabled", false)) {
            manager.cancel(NOTIFICATION_ID)
            return
        }
        if (!manager.areNotificationsEnabled()) return
        val title = prefs.getString("title", null) ?: context.getString(R.string.shortcut_add_expense)
        ensureChannel(context, prefs.getString("channelName", null) ?: title)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_hisab)
            .setContentTitle(title)
            .setContentText(prefs.getString("body", null))
            .setContentIntent(AddExpenseLink.pendingIntent(context, NOTIFICATION_ID))
            .setOngoing(true)
            .setSilent(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_RECOMMENDATION)
            .build()
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (denied: SecurityException) {
            // Permission revoked between the check and the call; nothing to show.
        }
    }

    // Minimum importance: in the shade, but no status bar icon or sound.
    private fun ensureChannel(context: Context, name: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_MIN).apply { setShowBadge(false) }
        context.getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
