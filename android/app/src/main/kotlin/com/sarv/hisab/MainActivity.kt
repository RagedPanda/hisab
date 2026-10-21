package com.sarv.hisab

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes the device SMS inbox to Dart. Only runs when the user has granted
 * READ_SMS / RECEIVE_SMS from the in-app opt-in; the Dart side never calls
 * these methods before that. Nothing is sent off the device.
 */
class MainActivity : FlutterActivity() {
    private var receiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readInbox" -> {
                    val since = call.argument<Number>("since")?.toLong() ?: 0L
                    val limit = call.argument<Number>("limit")?.toInt() ?: 2000
                    try {
                        result.success(readInbox(since, limit))
                    } catch (error: SecurityException) {
                        result.error("permission", "READ_SMS not granted", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                val newReceiver = object : BroadcastReceiver() {
                    override fun onReceive(context: Context, intent: Intent) {
                        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
                        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
                        if (messages.isEmpty()) return
                        // Multipart SMS arrive as several PDUs from the same sender; join them.
                        val body = messages.joinToString("") { it.messageBody ?: "" }
                        events.success(
                            mapOf(
                                "sender" to (messages[0].displayOriginatingAddress ?: ""),
                                "body" to body,
                                "date" to messages[0].timestampMillis,
                            )
                        )
                    }
                }
                val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(newReceiver, filter, Context.RECEIVER_EXPORTED)
                } else {
                    @Suppress("UnspecifiedRegisterReceiverFlag")
                    registerReceiver(newReceiver, filter)
                }
                receiver = newReceiver
            }

            override fun onCancel(arguments: Any?) {
                receiver?.let { unregisterReceiver(it) }
                receiver = null
            }
        })
    }

    private fun readInbox(sinceMillis: Long, limit: Int): List<Map<String, Any>> {
        val rows = ArrayList<Map<String, Any>>()
        val projection = arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE)
        val cursor = contentResolver.query(
            Uri.parse("content://sms/inbox"),
            projection,
            "${Telephony.Sms.DATE} > ?",
            arrayOf(sinceMillis.toString()),
            "${Telephony.Sms.DATE} ASC LIMIT $limit",
        ) ?: return rows
        cursor.use {
            val addressIndex = it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIndex = it.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val dateIndex = it.getColumnIndexOrThrow(Telephony.Sms.DATE)
            while (it.moveToNext()) {
                rows.add(
                    mapOf(
                        "sender" to (it.getString(addressIndex) ?: ""),
                        "body" to (it.getString(bodyIndex) ?: ""),
                        "date" to it.getLong(dateIndex),
                    )
                )
            }
        }
        return rows
    }

    override fun onDestroy() {
        receiver?.let { unregisterReceiver(it) }
        receiver = null
        super.onDestroy()
    }

    companion object {
        const val METHOD_CHANNEL = "com.sarv.hisab/sms"
        const val EVENT_CHANNEL = "com.sarv.hisab/sms_events"
    }
}
