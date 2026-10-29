package com.ragedpanda.hisab.launcher

import android.annotation.SuppressLint
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/**
 * Quick Settings tile "Add expense": collapses the shade and opens the
 * editor for a new expense with the keypad up. Unlocks first when the
 * device is locked.
 */
@RequiresApi(Build.VERSION_CODES.N)
class AddExpenseTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) unlockAndRun { openEditor() } else openEditor()
    }

    // The Intent overload throws on Android 14+; the PendingIntent one is
    // only there from 14.
    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openEditor() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(AddExpenseLink.pendingIntent(this, REQUEST_CODE))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(AddExpenseLink.intent(this))
        }
    }

    private companion object {
        const val REQUEST_CODE = 0x711E
    }
}
