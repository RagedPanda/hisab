package com.ragedpanda.hisab.launcher

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Dart's handle on what Hisab shows outside the app (see
 * lib/data/launcher/launcher_channel.dart). Each call only stores or
 * publishes what Dart already worked out.
 */
object LauncherChannel {
    private const val NAME = "com.ragedpanda.hisab/launcher"

    /** [context] is the activity: asking to add the tile needs a foreground app. */
    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "setQuickEntryShortcuts" -> {
                    QuickEntryShortcuts.publish(appContext, call.arguments as? List<*> ?: emptyList<Any>())
                    result.success(null)
                }
                "setAddExpenseNotification" -> {
                    AddExpenseNotifier.configure(appContext, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    result.success(null)
                }
                "requestAddTile" -> result.success(AddExpenseTileRequest.request(context))
                "updateSpendWidget" -> {
                    SpendWidgetProvider.save(appContext, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    result.success(null)
                }
                "requestPinWidget" -> result.success(SpendWidgetProvider.requestPin(context))
                else -> result.notImplemented()
            }
        }
    }
}
