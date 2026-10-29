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

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "setQuickEntryShortcuts" -> {
                    QuickEntryShortcuts.publish(appContext, call.arguments as? List<*> ?: emptyList<Any>())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
