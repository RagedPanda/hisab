package com.ragedpanda.hisab.sms

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/** One captured message, in the same shape the Dart side reads from the inbox. */
data class QueuedSms(val sender: String, val body: String, val date: Long) {
    fun toMap(): Map<String, Any> = mapOf("sender" to sender, "body" to body, "date" to date)
}

/**
 * Bank SMS received while Hisab was not running, kept in the app's private
 * SharedPreferences until the Dart side drains them on the next start or
 * resume. Bounded so a flood of messages cannot grow it without limit; the
 * inbox catch-up scan covers anything dropped.
 */
object SmsQueue {
    private const val PREFS = "hisab_sms_capture"
    private const val KEY_QUEUE = "queue"
    private const val MAX_ITEMS = 500

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun append(context: Context, sms: QueuedSms) {
        val current = read(prefs(context))
        val next = (current + sms).takeLast(MAX_ITEMS)
        prefs(context).edit().putString(KEY_QUEUE, encode(next)).commit()
    }

    /** Returns every queued message and empties the queue. */
    fun drain(context: Context): List<QueuedSms> {
        val current = read(prefs(context))
        prefs(context).edit().remove(KEY_QUEUE).commit()
        return current
    }

    private fun read(prefs: SharedPreferences): List<QueuedSms> = decode(prefs.getString(KEY_QUEUE, null))

    internal fun encode(items: List<QueuedSms>): String {
        val array = JSONArray()
        items.forEach { array.put(JSONObject().put("sender", it.sender).put("body", it.body).put("date", it.date)) }
        return array.toString()
    }

    internal fun decode(json: String?): List<QueuedSms> {
        if (json.isNullOrEmpty()) return emptyList()
        return try {
            val array = JSONArray(json)
            (0 until array.length()).map { index ->
                val item = array.getJSONObject(index)
                QueuedSms(item.optString("sender"), item.optString("body"), item.optLong("date"))
            }
        } catch (error: org.json.JSONException) {
            emptyList()
        }
    }
}
