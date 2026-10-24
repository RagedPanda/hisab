package com.sarv.hisab.sms

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.sarv.hisab.MainActivity
import com.sarv.hisab.R

/**
 * Posts "New bank transaction" when a bank SMS arrives while Hisab is in
 * the background. Silently does nothing when the user has not allowed
 * notifications (Android 13+ POST_NOTIFICATIONS) or turned the channel off.
 */
object SmsNotifier {
    private const val CHANNEL_ID = "bank_sms"
    private const val GROUP_KEY = "com.sarv.hisab.BANK_SMS"
    private const val SUMMARY_ID = 0x5D5

    fun post(context: Context, settings: SmsCaptureSettings, sms: QueuedSms) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        ensureChannel(context, settings.channelName)

        val tap = openBankSms(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_hisab)
            .setContentTitle(settings.title)
            .setContentText(settings.body(SmsCapturePolicy.amountLabel(sms.body), sms.sender))
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .setGroup(GROUP_KEY)
            .build()
        // Our own summary, so tapping the bundled group also opens Bank SMS
        // (a system-made summary has no content intent and opens Home).
        val summary = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_hisab)
            .setContentTitle(settings.title)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .setGroup(GROUP_KEY)
            .setGroupSummary(true)
            .build()
        try {
            manager.notify(notificationId(sms), notification)
            manager.notify(SUMMARY_ID, summary)
        } catch (denied: SecurityException) {
            // Permission revoked between the check and the call; nothing to show.
        }
    }

    private fun openBankSms(context: Context): PendingIntent {
        val open = Intent(Intent.ACTION_VIEW, Uri.parse("hisab://sms"), context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun notificationId(sms: QueuedSms): Int = SmsCapturePolicy.notificationId(sms.sender, sms.body)

    /**
     * Removes the notifications of messages the app has now processed
     * (added, sent to review or ignored), and the group summary with them
     * once no Bank SMS notification is left.
     */
    fun cancel(context: Context, messages: List<Pair<String, String>>) {
        if (messages.isEmpty()) return
        val manager = NotificationManagerCompat.from(context)
        val cancelled = messages.map { (sender, body) -> SmsCapturePolicy.notificationId(sender, body) }
        cancelled.forEach(manager::cancel)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val system = context.getSystemService(NotificationManager::class.java) ?: return
        val active = system.activeNotifications.filter { it.notification.group == GROUP_KEY }.map { it.id }
        if (SmsCapturePolicy.summaryOrphaned(active, cancelled, SUMMARY_ID)) manager.cancel(SUMMARY_ID)
    }

    private fun ensureChannel(context: Context, name: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT))
    }
}
