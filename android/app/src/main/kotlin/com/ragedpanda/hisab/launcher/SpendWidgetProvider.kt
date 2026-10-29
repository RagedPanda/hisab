package com.ragedpanda.hisab.launcher

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.ragedpanda.hisab.MainActivity
import com.ragedpanda.hisab.R

/**
 * Home-screen widget: this month's spend against last month's, with a +
 * that opens the editor for a new expense. Dart works out every word and
 * figure (lib/features/shortcuts/spend_widget_data.dart) and hands them over
 * through [save]; this only lays them out. Light and dark come from the
 * values-night colours, the background opacity from the app's setting.
 */
class SpendWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        val views = render(context)
        widgetIds.forEach { manager.updateAppWidget(it, views) }
    }

    companion object {
        private const val PREFS = "hisab_spend_widget"
        private const val OPEN_APP_REQUEST = 0x5E1
        private const val ADD_REQUEST = 0x5E2

        fun save(context: Context, data: Map<*, *>) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("title", data["title"] as? String)
                .putString("amount", data["amount"] as? String)
                .putString("comparison", data["comparison"] as? String)
                .putString("previous", data["previous"] as? String)
                .putLong("validUntil", (data["validUntil"] as? Number)?.toLong() ?: 0L)
                .putInt("opacity", (data["opacity"] as? Number)?.toInt() ?: 100)
                .apply()
            refresh(context)
        }

        /** Redraws every placed widget. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, SpendWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val views = render(context)
            ids.forEach { manager.updateAppWidget(it, views) }
        }

        /** Asks the launcher to place the widget; false where it cannot ask. */
        fun requestPin(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            return manager.requestPinAppWidget(ComponentName(context, SpendWidgetProvider::class.java), null, null)
        }

        private fun render(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_spend)
            val amount = prefs.getString("amount", null)
            // Before the app first ran, or once the month shown has ended.
            val current = amount != null && System.currentTimeMillis() < prefs.getLong("validUntil", 0L)
            views.setTextViewText(R.id.widget_title, if (current) prefs.getString("title", "") else context.getString(R.string.shortcut_add_expense))
            views.setTextViewText(R.id.widget_amount, if (current) amount else "—")
            // Empty when last month had no spend: that line is hidden then.
            val comparison = if (current) prefs.getString("comparison", "").orEmpty() else context.getString(R.string.widget_spend_open_app)
            views.setTextViewText(R.id.widget_comparison, comparison)
            views.setViewVisibility(R.id.widget_comparison, if (comparison.isEmpty()) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.widget_previous, if (current) prefs.getString("previous", "") else "")
            views.setViewVisibility(R.id.widget_previous, if (current) View.VISIBLE else View.GONE)
            val alpha = (prefs.getInt("opacity", 100).coerceIn(0, 100) * 255) / 100
            views.setInt(R.id.widget_background, "setImageAlpha", alpha)

            val openApp = Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            views.setOnClickPendingIntent(
                R.id.widget_body,
                PendingIntent.getActivity(context, OPEN_APP_REQUEST, openApp, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
            )
            views.setOnClickPendingIntent(R.id.widget_add, AddExpenseLink.pendingIntent(context, ADD_REQUEST))
            return views
        }
    }
}
