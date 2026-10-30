package com.ragedpanda.hisab.launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Posts the "Add expense" notification again after a reboot or an app update. */
class AddExpenseBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> AddExpenseNotifier.restore(context)
        }
    }
}
