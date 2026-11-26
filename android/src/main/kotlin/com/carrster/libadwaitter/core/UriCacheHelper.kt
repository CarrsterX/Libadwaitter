package com.carrster.libadwaitter.core

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream

internal object UriCacheHelper {
    fun copyUriToCache(context: Context, uri: Uri): String? {
        return try {
            var displayName = "picked_file"
            context.contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) {
                        val name = cursor.getString(idx)
                        if (!name.isNullOrBlank()) {
                            displayName = name.replace(Regex("[^a-zA-Z0-9._-]"), "_")
                        }
                    }
                }
            }
            val target = File(
                context.cacheDir,
                "adw_portal_${System.currentTimeMillis()}_$displayName",
            )
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(target).use { output ->
                    input.copyTo(output)
                }
            }
            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }
}
