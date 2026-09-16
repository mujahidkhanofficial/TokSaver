package com.afridilabz.tiktok_downloader

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

/**
 * Enterprise Android MediaStore and Storage Adapter.
 *
 * Implements modern Scoped Storage for Android 10+ (API 29 through 36 / Android 16)
 * via ContentResolver and MediaStore with IS_PENDING transactional safety.
 *
 * Backward-compatible with Android 8-9 (API 26-28) using public media directories
 * and MediaScannerConnection.
 */
class MediaStoreManager(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.afridilabz.tiktok_downloader/media_store"
        private const val BUFFER_SIZE = 65536 // 64 KiB buffer for streaming

        fun registerWith(messenger: io.flutter.plugin.common.BinaryMessenger, context: Context) {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val handler = MediaStoreManager(context)
            channel.setMethodCallHandler(handler)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveToMediaStore" -> {
                val tempFilePath = call.argument<String>("tempFilePath")
                val displayName = call.argument<String>("displayName")
                val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                val isAudio = call.argument<Boolean>("isAudio") ?: false
                val relativeSubDir = call.argument<String>("relativeSubDir") ?: "TokSaver"

                if (tempFilePath == null || displayName == null) {
                    result.error("INVALID_ARGUMENTS", "tempFilePath and displayName are required", null)
                    return
                }

                try {
                    val res = saveMedia(tempFilePath, displayName, mimeType, isAudio, relativeSubDir)
                    result.success(res)
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", e.message ?: "Failed to save to MediaStore", e.localizedMessage)
                }
            }
            "deleteMedia" -> {
                val uriStr = call.argument<String>("uri")
                val storageType = call.argument<String>("storageType") ?: "media_store"
                val filePath = call.argument<String>("filePath")

                val success = deleteMediaItem(uriStr, storageType, filePath)
                result.success(success)
            }
            "mediaExists" -> {
                val uriStr = call.argument<String>("uri")
                val storageType = call.argument<String>("storageType") ?: "media_store"
                val filePath = call.argument<String>("filePath")

                val exists = checkMediaExists(uriStr, storageType, filePath)
                result.success(exists)
            }
            "openMedia" -> {
                val uriStr = call.argument<String>("uri")
                val mimeType = call.argument<String>("mimeType") ?: "video/*"
                val title = call.argument<String>("title") ?: "Video"

                if (uriStr == null) {
                    result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    return
                }

                try {
                    openMediaItem(uriStr, mimeType, title)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("OPEN_ERROR", e.message ?: "Unable to open file", null)
                }
            }
            "shareMedia" -> {
                val uriStr = call.argument<String>("uri")
                val mimeType = call.argument<String>("mimeType") ?: "video/*"
                val title = call.argument<String>("title") ?: "TikTok Download"

                if (uriStr == null) {
                    result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    return
                }

                try {
                    shareMediaItem(uriStr, mimeType, title)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.message ?: "Unable to share file", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun saveMedia(
        tempFilePath: String,
        displayName: String,
        mimeType: String,
        isAudio: Boolean,
        relativeSubDir: String
    ): Map<String, Any> {
        val tempFile = File(tempFilePath)
        if (!tempFile.exists() || !tempFile.isFile) {
            throw IOException("Temporary source file does not exist: $tempFilePath")
        }

        val totalBytes = tempFile.length()
        if (totalBytes <= 0) {
            throw IOException("Temporary source file is empty (0 bytes).")
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveModernMediaStore(tempFile, displayName, mimeType, isAudio, relativeSubDir, totalBytes)
        } else {
            saveLegacyExternalStorage(tempFile, displayName, mimeType, isAudio, relativeSubDir, totalBytes)
        }
    }

    /**
     * Modern Android (API 29 - 36 / Android 16) MediaStore implementation.
     * Uses IS_PENDING = 1 during streaming and updates to IS_PENDING = 0 upon commit.
     */
    private fun saveModernMediaStore(
        tempFile: File,
        displayName: String,
        mimeType: String,
        isAudio: Boolean,
        relativeSubDir: String,
        expectedBytes: Long
    ): Map<String, Any> {
        val resolver: ContentResolver = context.contentResolver
        val isImage = mimeType.startsWith("image/")
        val relativeFolder = when {
            isImage -> "${Environment.DIRECTORY_PICTURES}/$relativeSubDir"
            isAudio -> "${Environment.DIRECTORY_MUSIC}/$relativeSubDir"
            else -> "${Environment.DIRECTORY_MOVIES}/$relativeSubDir"
        }

        val collectionUri: Uri = when {
            isImage -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                }
            }
            isAudio -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }
            }
            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                }
            }
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativeFolder)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val itemUri: Uri = resolver.insert(collectionUri, contentValues)
            ?: throw IOException("Failed to create MediaStore entry for $displayName")

        var writtenBytes: Long = 0

        try {
            resolver.openOutputStream(itemUri, "w")?.use { outputStream ->
                FileInputStream(tempFile).use { inputStream ->
                    val buffer = ByteArray(BUFFER_SIZE)
                    var read: Int
                    while (inputStream.read(buffer).also { read = it } != -1) {
                        outputStream.write(buffer, 0, read)
                        writtenBytes += read
                    }
                    outputStream.flush()
                }
            } ?: throw IOException("Could not open output stream for MediaStore URI: $itemUri")

            if (writtenBytes != expectedBytes) {
                throw IOException("Written byte count mismatch: wrote $writtenBytes of $expectedBytes bytes.")
            }

            // Commit transaction: IS_PENDING = 0
            val commitValues = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(itemUri, commitValues, null, null)

            // Safe cleanup of temporary source file
            tempFile.delete()

            return mapOf(
                "uri" to itemUri.toString(),
                "storageType" to "media_store",
                "displayName" to displayName,
                "mimeType" to mimeType,
                "relativePath" to relativeFolder,
                "size" to writtenBytes
            )
        } catch (e: Exception) {
            // Rollback: clean up incomplete pending item to avoid zero-byte ghost files
            try {
                resolver.delete(itemUri, null, null)
            } catch (_: Exception) {}
            throw e
        }
    }

    /**
     * Legacy Android (API 26 - 28) external storage implementation.
     * Writes to public Movies/Music directories and indexes via MediaScannerConnection.
     */
    private fun saveLegacyExternalStorage(
        tempFile: File,
        displayName: String,
        mimeType: String,
        isAudio: Boolean,
        relativeSubDir: String,
        expectedBytes: Long
    ): Map<String, Any> {
        val isImage = mimeType.startsWith("image/")
        val baseDir = when {
            isImage -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            isAudio -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
            else -> Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
        }

        val targetDir = File(baseDir, relativeSubDir)
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        val targetFile = resolveUniqueFile(targetDir, displayName)
        var writtenBytes: Long = 0

        try {
            FileOutputStream(targetFile).use { outputStream ->
                FileInputStream(tempFile).use { inputStream ->
                    val buffer = ByteArray(BUFFER_SIZE)
                    var read: Int
                    while (inputStream.read(buffer).also { read = it } != -1) {
                        outputStream.write(buffer, 0, read)
                        writtenBytes += read
                    }
                    outputStream.flush()
                }
            }

            if (writtenBytes != expectedBytes) {
                targetFile.delete()
                throw IOException("Legacy copy mismatch: wrote $writtenBytes of $expectedBytes bytes.")
            }

            // Scan file into Android media library
            MediaScannerConnection.scanFile(
                context,
                arrayOf(targetFile.absolutePath),
                arrayOf(mimeType),
                null
            )

            // Delete temporary file
            tempFile.delete()

            return mapOf(
                "uri" to targetFile.absolutePath,
                "filePath" to targetFile.absolutePath,
                "storageType" to "legacy_file",
                "displayName" to targetFile.name,
                "mimeType" to mimeType,
                "relativePath" to "$relativeSubDir/${targetFile.name}",
                "size" to writtenBytes
            )
        } catch (e: Exception) {
            if (targetFile.exists()) {
                targetFile.delete()
            }
            throw e
        }
    }

    private fun resolveUniqueFile(directory: File, fileName: String): File {
        var file = File(directory, fileName)
        if (!file.exists()) return file

        val nameWithoutExt = fileName.substringBeforeLast('.', fileName)
        val ext = if (fileName.contains('.')) ".${fileName.substringAfterLast('.')}" else ""
        var counter = 1

        while (file.exists()) {
            file = File(directory, "$nameWithoutExt ($counter)$ext")
            counter++
        }
        return file
    }

    private fun deleteMediaItem(uriStr: String?, storageType: String, filePath: String?): Boolean {
        return try {
            if (uriStr != null && uriStr.startsWith("content://")) {
                val uri = Uri.parse(uriStr)
                val rows = context.contentResolver.delete(uri, null, null)
                rows > 0
            } else if (!filePath.isNullOrEmpty()) {
                val f = File(filePath)
                if (f.exists()) f.delete() else false
            } else if (uriStr != null && !uriStr.startsWith("content://")) {
                val f = File(uriStr)
                if (f.exists()) f.delete() else false
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun checkMediaExists(uriStr: String?, storageType: String, filePath: String?): Boolean {
        if (uriStr != null && uriStr.startsWith("content://")) {
            return try {
                val uri = Uri.parse(uriStr)
                context.contentResolver.openFileDescriptor(uri, "r")?.use {
                    true
                } ?: false
            } catch (_: Exception) {
                false
            }
        }

        val pathToCheck = filePath ?: uriStr
        if (!pathToCheck.isNullOrEmpty()) {
            return try {
                File(pathToCheck).exists()
            } catch (_: Exception) {
                false
            }
        }

        return false
    }

    private fun openMediaItem(uriStr: String, mimeType: String, title: String) {
        val uri: Uri = if (uriStr.startsWith("content://")) {
            Uri.parse(uriStr)
        } else {
            val file = File(uriStr)
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        context.startActivity(intent)
    }

    private fun shareMediaItem(uriStr: String, mimeType: String, title: String) {
        val uri: Uri = if (uriStr.startsWith("content://")) {
            Uri.parse(uriStr)
        } else {
            val file = File(uriStr)
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
        }

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, title)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(shareIntent, "Share $title").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        context.startActivity(chooser)
    }
}
