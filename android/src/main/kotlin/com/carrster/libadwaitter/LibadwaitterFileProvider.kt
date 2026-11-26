package com.carrster.libadwaitter

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileNotFoundException
import java.util.concurrent.ConcurrentHashMap

/**
 * Lightweight zero-dependency ContentProvider that exposes explicitly shared
 * local files via `content://<applicationId>.libadwaitter.fileprovider/<token>/<name>`
 * for Android's native Share Sheet without requiring AndroidX FileProvider.
 */
class LibadwaitterFileProvider : ContentProvider() {
    companion object {
        private val sharedFiles = ConcurrentHashMap<String, File>()

        fun registerFile(authority: String, file: File): Uri {
            val token = "${System.nanoTime()}_${file.name.hashCode()}"
            sharedFiles[token] = file
            return Uri.Builder()
                .scheme("content")
                .authority(authority)
                .appendPath(token)
                .appendPath(file.name)
                .build()
        }
    }

    private fun resolveFile(uri: Uri): File {
        val segments = uri.pathSegments
        val token = segments.firstOrNull()
            ?: throw FileNotFoundException("Invalid shared file URI: $uri")
        val file = sharedFiles[token]
            ?: throw FileNotFoundException("Shared file not found for token: $token")
        if (!file.exists() || !file.canRead()) {
            throw FileNotFoundException("File not readable: ${file.absolutePath}")
        }
        return file
    }

    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        val file = resolveFile(uri)
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String {
        val file = try {
            resolveFile(uri)
        } catch (_: Exception) {
            return "application/octet-stream"
        }
        val ext = file.extension.lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
            ?: "application/octet-stream"
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val file = resolveFile(uri)
        val cols = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        val cursor = MatrixCursor(cols, 1)
        val row = arrayOfNulls<Any>(cols.size)
        for (i in cols.indices) {
            row[i] = when (cols[i]) {
                OpenableColumns.DISPLAY_NAME -> file.name
                OpenableColumns.SIZE -> file.length()
                else -> null
            }
        }
        cursor.addRow(row)
        return cursor
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0
}
