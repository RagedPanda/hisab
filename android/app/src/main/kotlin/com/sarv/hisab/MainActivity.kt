package com.sarv.hisab

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.sarv.hisab.sms.SmsCaptureBridge
import com.sarv.hisab.sms.SmsCaptureSettings
import com.sarv.hisab.sms.SmsQueue

/**
 * Exposes the device SMS inbox and the background capture queue
 * (see sms/SmsReceiver.kt) to Dart. Only runs when the user has granted
 * READ_SMS / RECEIVE_SMS from the in-app opt-in; the Dart side never calls
 * these methods before that. Nothing is sent off the device.
 */
class MainActivity : FlutterActivity() {
    // Text shared from another app arrives as ACTION_SEND. Turn it into the
    // hisab://sms?text=... link before Flutter reads the intent, so the
    // router opens the SMS paste screen as it does for any deep link.
    override fun onCreate(savedInstanceState: Bundle?) {
        sharedTextAsLink(intent)?.let { setIntent(it) }
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        val link = sharedTextAsLink(intent) ?: intent
        setIntent(link)
        super.onNewIntent(link)
    }

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
                "drainQueue" -> result.success(SmsQueue.drain(this).map { it.toMap() })
                "configureCapture" -> {
                    val arguments = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    SmsCaptureSettings.save(this, SmsCaptureSettings.fromArguments(arguments))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Live signal from the manifest receiver (SmsReceiver) while the app runs;
        // Dart answers each one by draining the native queue.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                SmsCaptureBridge.sink = events
            }

            override fun onCancel(arguments: Any?) {
                SmsCaptureBridge.sink = null
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

    override fun onResume() {
        super.onResume()
        SmsCaptureBridge.appVisible = true
    }

    override fun onPause() {
        SmsCaptureBridge.appVisible = false
        super.onPause()
    }

    override fun onDestroy() {
        SmsCaptureBridge.sink = null
        super.onDestroy()
    }

    companion object {
        const val METHOD_CHANNEL = "com.sarv.hisab/sms"
        const val EVENT_CHANNEL = "com.sarv.hisab/sms_events"
    }
}

/**
 * VIEW intent for hisab://sms?text=<shared text> when [intent] is a plain-text
 * share, or null for anything else.
 */
internal fun sharedTextAsLink(intent: Intent?): Intent? {
    if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") return null
    val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim().orEmpty()
    if (text.isEmpty()) return null
    val link = Uri.Builder().scheme("hisab").authority("sms").appendQueryParameter("text", text).build()
    return Intent(Intent.ACTION_VIEW, link)
}
