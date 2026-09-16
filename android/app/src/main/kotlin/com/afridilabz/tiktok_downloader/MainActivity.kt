package com.afridilabz.tiktok_downloader

import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.MediaScannerConnection
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Rational
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DOWNLOAD_SERVICE_CHANNEL = "com.afridilabz.tiktok_downloader/download_service"
    private val MEDIA_SCANNER_CHANNEL = "com.afridilabz.tiktok_downloader/media_scanner"
    private val SHARE_INTENT_CHANNEL = "com.afridilabz.tiktok_downloader/share_intent"
    private val PIP_CHANNEL = "com.afridilabz.tiktok_downloader/pip"
    private val AUDIO_UTILITY_CHANNEL = "com.afridilabz.tiktok_downloader/audio_utility"

    private var shareChannel: MethodChannel? = null
    private var pipChannel: MethodChannel? = null
    private var initialSharedText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleShareIntent(intent, isInitial = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent, isInitial = false)
    }

    private fun handleShareIntent(intent: Intent?, isInitial: Boolean) {
        if (intent == null) return
        if (intent.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                ?: intent.clipData?.getItemAt(0)?.text?.toString()

            if (!sharedText.isNullOrBlank()) {
                if (isInitial) {
                    initialSharedText = sharedText
                }
                shareChannel?.invokeMethod("onSharedTextReceived", sharedText)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register modern MediaStore & Scoped Storage Manager (Android 10 - 16 / API 26-36)
        MediaStoreManager.registerWith(flutterEngine.dartExecutor.binaryMessenger, applicationContext)

        // Download foreground service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOAD_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val title = call.argument<String>("title") ?: "Downloading video"
                    DownloadService.start(applicationContext, title)
                    result.success(true)
                }
                "updateProgress" -> {
                    val title = call.argument<String>("title") ?: "Downloading video"
                    val text = call.argument<String>("text") ?: ""
                    val progress = call.argument<Int>("progress") ?: 0
                    DownloadService.updateProgress(applicationContext, title, text, progress)
                    result.success(true)
                }
                "stopService" -> {
                    DownloadService.stop(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Media scanner channel fallback
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCANNER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(path),
                        null
                    ) { _, _ -> }
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Path cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Share Intent Channel
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_INTENT_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedText" -> {
                        val text = initialSharedText
                        initialSharedText = null // Consume once
                        result.success(text)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Picture-in-Picture Channel
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPipSupported" -> {
                        val supported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                        } else {
                            false
                        }
                        result.success(supported)
                    }
                    "enterPictureInPicture" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                val num = call.argument<Int>("numerator") ?: 9
                                val den = call.argument<Int>("denominator") ?: 16
                                val rawRatio = (num.toFloat() / den.toFloat()).coerceIn(0.418410f, 2.390000f)

                                val rational = if (rawRatio <= 0.5625f) {
                                    Rational(9, 16)
                                } else if (rawRatio >= 1.777f) {
                                    Rational(16, 9)
                                } else {
                                    Rational(num.coerceIn(1, 1000), den.coerceIn(1, 1000))
                                }

                                val params = PictureInPictureParams.Builder()
                                    .setAspectRatio(rational)
                                    .build()

                                val entered = enterPictureInPictureMode(params)
                                result.success(entered)
                            } catch (e: Exception) {
                                result.error("PIP_ERROR", e.message, null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Audio & Ringtone Utility Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_UTILITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAsRingtone" -> {
                    val uriStr = call.argument<String>("uri")
                    val title = call.argument<String>("title") ?: "Ringtone"
                    if (uriStr != null) {
                        try {
                            val uri = Uri.parse(uriStr)
                            val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                                putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_RINGTONE)
                                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, uri)
                                putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, title)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("RINGTONE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}