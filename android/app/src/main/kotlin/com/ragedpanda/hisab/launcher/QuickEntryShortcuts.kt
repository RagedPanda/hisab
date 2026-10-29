package com.ragedpanda.hisab.launcher

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.ragedpanda.hisab.MainActivity
import com.ragedpanda.hisab.R

/**
 * Publishes the quick-entry launcher shortcuts Dart built (see
 * lib/domain/launcher/quick_entry_shortcuts.dart). Each opens its
 * hisab://entry?quick=<id> link, which the router turns into the editor.
 */
object QuickEntryShortcuts {
    /** Static shortcuts in res/xml/shortcuts.xml; they share the launcher's limit. */
    private const val STATIC_SHORTCUTS = 2

    fun publish(context: Context, rows: List<*>) {
        val room = (ShortcutManagerCompat.getMaxShortcutCountPerActivity(context) - STATIC_SHORTCUTS).coerceAtLeast(0)
        val shortcuts = rows.mapNotNull { it as? Map<*, *> }.take(room).mapNotNull { row -> build(context, row) }
        try {
            ShortcutManagerCompat.setDynamicShortcuts(context, shortcuts)
        } catch (error: IllegalArgumentException) {
            // A launcher that rejects the set keeps the previous one.
        } catch (error: IllegalStateException) {
            // Rate-limited or the user is locked; the next change publishes again.
        }
    }

    private fun build(context: Context, row: Map<*, *>): ShortcutInfoCompat? {
        val id = row["id"] as? String ?: return null
        val shortLabel = row["shortLabel"] as? String ?: return null
        val link = row["link"] as? String ?: return null
        val open = Intent(Intent.ACTION_VIEW, Uri.parse(link), context, MainActivity::class.java)
        return ShortcutInfoCompat.Builder(context, id)
            .setShortLabel(shortLabel)
            .setLongLabel(row["longLabel"] as? String ?: shortLabel)
            .setIcon(IconCompat.createWithResource(context, R.drawable.ic_shortcut_quick))
            .setIntent(open)
            .build()
    }
}
