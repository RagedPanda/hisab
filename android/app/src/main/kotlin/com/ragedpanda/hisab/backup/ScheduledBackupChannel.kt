package com.ragedpanda.hisab.backup

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Dart's handle on scheduled backups (lib/data/backup/scheduled_backup_channel.dart):
 * the chosen folder, the saved passphrase and the background job. Registered
 * on the app's engine with its [activity] (the folder picker needs one) and
 * on the background job's headless engine without.
 */
class ScheduledBackupChannel(
    context: Context,
    messenger: BinaryMessenger,
    private val activity: Activity? = null,
    private val onBackgroundRunFinished: () -> Unit = {},
) {
    private val appContext = context.applicationContext
    private val main = Handler(Looper.getMainLooper())
    private var pendingPick: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "writeFile" -> onFolder(call, result) { folder ->
                BackupFolderStorage.write(appContext, folder, call.argument<String>("name")!!, call.argument<ByteArray>("bytes")!!)
                null
            }
            "listFiles" -> onFolder(call, result) { folder -> BackupFolderStorage.children(appContext, folder).map { it.first } }
            "deleteFile" -> onFolder(call, result) { folder ->
                BackupFolderStorage.delete(appContext, folder, call.argument<String>("name")!!)
                null
            }
            "readPassphrase" -> result.success(BackupPassphraseVault.read(appContext))
            "writePassphrase" -> {
                BackupPassphraseVault.write(appContext, call.argument<String>("passphrase")!!)
                result.success(null)
            }
            "deletePassphrase" -> {
                BackupPassphraseVault.delete(appContext)
                result.success(null)
            }
            "setBackgroundSchedule" -> {
                ScheduledBackupJob.setEnabled(appContext, call.argument<Boolean>("enabled") == true)
                result.success(null)
            }
            "backgroundRunFinished" -> {
                result.success(null)
                main.post(onBackgroundRunFinished)
            }
            else -> result.notImplemented()
        }
    }

    /** Runs folder I/O off the main thread; any failure is reported as a "folder" error. */
    private fun onFolder(call: MethodCall, result: MethodChannel.Result, work: (Uri) -> Any?) {
        val folder = Uri.parse(call.argument<String>("folder") ?: "")
        io.execute {
            try {
                val value = work(folder)
                main.post { result.success(value) }
            } catch (error: Exception) {
                main.post { result.error("folder", error.message ?: error.javaClass.simpleName, null) }
            }
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        val host = activity
        if (host == null || pendingPick != null) {
            result.error("busy", "The folder picker can't open now", null)
            return
        }
        pendingPick = result
        host.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), PICK_FOLDER_REQUEST)
    }

    /** Forwarded from MainActivity; true when the result was the folder picker's. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_FOLDER_REQUEST) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(null)
            return true
        }
        try {
            BackupFolderStorage.keepAccess(appContext, treeUri)
            releaseOtherFolders(treeUri)
            result.success(mapOf("uri" to treeUri.toString(), "name" to BackupFolderStorage.displayName(appContext, treeUri)))
        } catch (error: Exception) {
            result.error("folder", error.message ?: error.javaClass.simpleName, null)
        }
        return true
    }

    /** Hisab keeps access to one backup folder: the grant on an earlier pick is dropped. */
    private fun releaseOtherFolders(keep: Uri) {
        appContext.contentResolver.persistedUriPermissions
            .map { it.uri }
            .filter { it != keep && DocumentsContract.isTreeUri(it) }
            .forEach { BackupFolderStorage.releaseAccess(appContext, it) }
    }

    companion object {
        const val NAME = "com.ragedpanda.hisab/scheduled_backup"
        private const val PICK_FOLDER_REQUEST = 4207
        private val io = Executors.newSingleThreadExecutor()
    }
}
