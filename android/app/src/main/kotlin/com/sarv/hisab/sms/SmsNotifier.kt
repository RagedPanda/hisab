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

    fun post(context: Context, settings: SmsCaptureSettings, sms: QueuedSms) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        ensureChannel(context, settings.channelName)

        val open = Intent(Intent.ACTION_VIEW, Uri.parse("hisab://sms"), context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val tap = PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_hisab)
            .setContentTitle(settings.title)
            .setContentText(settings.body(SmsCapturePolicy.amountLabel(sms.body), sms.sender))
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(notificationId(sms), notification)
        } catch (denied: SecurityException) {
            // Permission revoked between the check and the call; nothing to show.
        }
    }

    private fun notificationId(sms: QueuedSms): Int = (sms.sender + sms.body).hashCode()

    private fun ensureChannel(context: Context, name: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT))
    }
}
