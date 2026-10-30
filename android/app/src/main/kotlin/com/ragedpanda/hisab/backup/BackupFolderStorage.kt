package com.ragedpanda.hisab.backup

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract

/**
 * The folder the user picked for scheduled backups, reached through the
 * Storage Access Framework: Hisab holds a persisted grant to that one tree
 * and nothing else, so no storage permission is needed.
 */
object BackupFolderStorage {
    private const val BACKUP_MIME_TYPE = "application/octet-stream"

    /** Keeps read/write access to [treeUri] across reboots. */
    fun keepAccess(context: Context, treeUri: Uri) {
        context.contentResolver.takePersistableUriPermission(
            treeUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
    }

    /** Drops the grant on a folder that is no longer used. */
    fun releaseAccess(context: Context, treeUri: Uri) {
        try {
            context.contentResolver.releasePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Not held any more; nothing to release.
        }
    }

    fun displayName(context: Context, treeUri: Uri): String {
        val folderUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))
        context.contentResolver.query(folderUri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) return it.getString(0) ?: ""
        }
        return ""
    }

    /** Name and document URI of each file directly in the folder. */
    fun children(context: Context, treeUri: Uri): List<Pair<String, Uri>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))
        val projection = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME)
        val rows = ArrayList<Pair<String, Uri>>()
        val cursor = context.contentResolver.query(childrenUri, projection, null, null, null)
            ?: throw IllegalStateException("Folder can't be listed")
        cursor.use {
            while (it.moveToNext()) {
                val documentId = it.getString(0) ?: continue
                val name = it.getString(1) ?: continue
                rows.add(name to DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId))
            }
        }
        return rows
    }

    /** Writes [bytes] as [name], replacing a file of that name. A failed write leaves no partial file behind. */
    fun write(context: Context, treeUri: Uri, name: String, bytes: ByteArray) {
        val resolver = context.contentResolver
        val existing = children(context, treeUri).firstOrNull { it.first == name }?.second
        val folderUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))
        val target = existing ?: DocumentsContract.createDocument(resolver, folderUri, BACKUP_MIME_TYPE, name)
            ?: throw IllegalStateException("Couldn't create $name")
        try {
            val stream = resolver.openOutputStream(target, "wt") ?: throw IllegalStateException("Couldn't open $name")
            stream.use { it.write(bytes) }
        } catch (error: Exception) {
            if (existing == null) DocumentsContract.deleteDocument(resolver, target)
            throw error
        }
    }

    fun delete(context: Context, treeUri: Uri, name: String) {
        val target = children(context, treeUri).firstOrNull { it.first == name }?.second ?: return
        DocumentsContract.deleteDocument(context.contentResolver, target)
    }
}
