package com.ragedpanda.hisab.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * Manifest-declared, so Android starts it for every incoming SMS even when
 * Hisab is not running. Bank-like messages are queued for the Dart ingest
 * pipeline; a live app is told straight away, otherwise a notification is
 * posted and the queue is drained on the next start or resume.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val settings = SmsCaptureSettings.load(context)
        if (!settings.enabled) return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        if (messages.isEmpty()) return
        // Multipart SMS arrive as several PDUs from the same sender; join them.
        val sender = messages[0].displayOriginatingAddress ?: ""
        val body = messages.joinToString("") { it.messageBody ?: "" }
        if (!SmsCapturePolicy.shouldCapture(sender, body)) return

        // The inbox stores the time the phone received the message, so use the
        // same clock here: both paths then hash to the same sms_log id.
        val sms = QueuedSms(sender, body, System.currentTimeMillis())
        SmsQueue.append(context, sms)
        SmsCaptureBridge.signalQueued()
        if (settings.notify && !SmsCaptureBridge.appVisible && SmsCapturePolicy.shouldNotify(body)) {
            SmsNotifier.post(context, settings, sms)
        }
    }
}
