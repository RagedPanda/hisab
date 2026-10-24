package com.sarv.hisab.sms

import android.content.Context

/**
 * What the Dart side told the native layer: whether the user opted in to
 * Bank SMS, and the notification text in the user's language (all text
 * lives in the app's ARB dictionaries, so Dart sends it down).
 */
data class SmsCaptureSettings(
    val enabled: Boolean,
    val channelName: String,
    val title: String,
    /** Contains "{amount}" and "{sender}" placeholders. */
    val bodyWithAmount: String,
    /** Contains a "{sender}" placeholder. */
    val bodyWithoutAmount: String,
) {
    fun body(amount: String?, sender: String): String =
        (if (amount == null) bodyWithoutAmount else bodyWithAmount.replace("{amount}", amount)).replace("{sender}", sender)

    companion object {
        private const val PREFS = "hisab_sms_capture"

        val DEFAULT = SmsCaptureSettings(
            enabled = false,
            channelName = "Bank SMS",
            title = "New bank transaction",
            bodyWithAmount = "{amount} from {sender}. Tap to review.",
            bodyWithoutAmount = "From {sender}. Tap to review.",
        )

        fun load(context: Context): SmsCaptureSettings {
            val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return SmsCaptureSettings(
                enabled = prefs.getBoolean("enabled", DEFAULT.enabled),
                channelName = prefs.getString("channelName", null) ?: DEFAULT.channelName,
                title = prefs.getString("title", null) ?: DEFAULT.title,
                bodyWithAmount = prefs.getString("bodyWithAmount", null) ?: DEFAULT.bodyWithAmount,
                bodyWithoutAmount = prefs.getString("bodyWithoutAmount", null) ?: DEFAULT.bodyWithoutAmount,
            )
        }

        fun save(context: Context, settings: SmsCaptureSettings) {
            context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean("enabled", settings.enabled)
                .putString("channelName", settings.channelName)
                .putString("title", settings.title)
                .putString("bodyWithAmount", settings.bodyWithAmount)
                .putString("bodyWithoutAmount", settings.bodyWithoutAmount)
                .commit()
        }

        fun fromArguments(arguments: Map<*, *>): SmsCaptureSettings = SmsCaptureSettings(
            enabled = arguments["enabled"] as? Boolean ?: false,
            channelName = arguments["channelName"] as? String ?: DEFAULT.channelName,
            title = arguments["title"] as? String ?: DEFAULT.title,
            bodyWithAmount = arguments["bodyWithAmount"] as? String ?: DEFAULT.bodyWithAmount,
            bodyWithoutAmount = arguments["bodyWithoutAmount"] as? String ?: DEFAULT.bodyWithoutAmount,
        )
    }
}
