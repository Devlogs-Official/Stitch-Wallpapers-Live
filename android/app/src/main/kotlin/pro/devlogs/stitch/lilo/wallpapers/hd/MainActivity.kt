package pro.devlogs.stitch.lilo.wallpapers.hd

import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "wallpaper.apply/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyWallpaper" -> applyStaticWallpaper(
                        call.argument<String>("imageUrl").orEmpty(),
                        call.argument<String>("target") ?: "both",
                        result,
                    )
                    "applyLiveWallpaper" -> applyLiveWallpaper(
                        call.argument<String>("videoUrl").orEmpty(),
                        call.argument<String>("id").orEmpty(),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyStaticWallpaper(
        imageUrl: String,
        target: String,
        result: MethodChannel.Result,
    ) {
        if (imageUrl.isBlank()) {
            result.error("INVALID_IMAGE_URL", "Wallpaper image URL is missing.", null)
            return
        }

        thread {
            try {
                val connection = openConnection(imageUrl)
                if (connection.responseCode !in 200..299) {
                    connection.disconnect()
                    postError(result, "DOWNLOAD_FAILED", "Failed to download wallpaper.")
                    return@thread
                }
                val bitmap = connection.inputStream.use {
                    BitmapFactory.decodeStream(BufferedInputStream(it))
                }
                connection.disconnect()
                if (bitmap == null) {
                    postError(result, "DECODE_FAILED", "Unable to decode wallpaper image.")
                    return@thread
                }

                val manager = WallpaperManager.getInstance(applicationContext)
                when (target) {
                    "home" -> setBitmap(manager, bitmap, WallpaperManager.FLAG_SYSTEM)
                    "lock" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                            postError(result, "UNSUPPORTED", "Lock screen apply needs Android 7.0+.")
                            return@thread
                        }
                        setBitmap(manager, bitmap, WallpaperManager.FLAG_LOCK)
                    }
                    else -> {
                        setBitmap(manager, bitmap, WallpaperManager.FLAG_SYSTEM)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            setBitmap(manager, bitmap, WallpaperManager.FLAG_LOCK)
                        }
                    }
                }
                postSuccess(result, "Wallpaper applied successfully.")
            } catch (error: Exception) {
                postError(
                    result,
                    "APPLY_FAILED",
                    error.localizedMessage ?: "Failed to apply wallpaper.",
                )
            }
        }
    }

    private fun setBitmap(
        manager: WallpaperManager,
        bitmap: android.graphics.Bitmap,
        flag: Int,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            manager.setBitmap(bitmap, null, true, flag)
        } else {
            manager.setBitmap(bitmap)
        }
    }

    private fun applyLiveWallpaper(
        videoUrl: String,
        id: String,
        result: MethodChannel.Result,
    ) {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_LIVE_WALLPAPER)) {
            result.error("UNSUPPORTED", "This device does not support live wallpapers.", null)
            return
        }
        if (videoUrl.isBlank() || id.isBlank()) {
            result.error("INVALID_VIDEO_URL", "Live wallpaper video URL is missing.", null)
            return
        }

        thread {
            val targetFile = File(filesDir, "live_wallpaper_$id.mp4")
            val partFile = File(filesDir, "live_wallpaper_$id.mp4.part")
            try {
                val connection = openConnection(videoUrl)
                if (connection.responseCode !in 200..299) {
                    connection.disconnect()
                    postError(result, "DOWNLOAD_FAILED", "Failed to download live wallpaper.")
                    return@thread
                }
                connection.inputStream.use { input ->
                    FileOutputStream(partFile).use { output -> input.copyTo(output) }
                }
                connection.disconnect()

                targetFile.delete()
                if (!partFile.renameTo(targetFile)) {
                    partFile.copyTo(targetFile, overwrite = true)
                    partFile.delete()
                }
                VideoLiveWallpaperService.setSource(applicationContext, targetFile.absolutePath)
                Handler(Looper.getMainLooper()).post { openLiveWallpaperPicker(result) }
            } catch (error: Exception) {
                partFile.delete()
                postError(
                    result,
                    "DOWNLOAD_FAILED",
                    error.localizedMessage ?: "Failed to download live wallpaper.",
                )
            }
        }
    }

    private fun openConnection(url: String): HttpURLConnection =
        (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15_000
            readTimeout = 30_000
            instanceFollowRedirects = true
            connect()
        }

    private fun openLiveWallpaperPicker(result: MethodChannel.Result) {
        if (isFinishing || isDestroyed) {
            result.error("ACTIVITY_GONE", "App was closed before the wallpaper screen could open.", null)
            return
        }
        val preview = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
            putExtra(
                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                ComponentName(this@MainActivity, VideoLiveWallpaperService::class.java),
            )
        }
        if (startActivitySafely(preview)) {
            result.success("Choose Set wallpaper on the next screen.")
            return
        }
        if (startActivitySafely(Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))) {
            result.success("Choose Stitch Wallpapers from the list to set it.")
            return
        }
        result.error("UNSUPPORTED", "This device has no live wallpaper picker.", null)
    }

    private fun startActivitySafely(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }

    private fun postSuccess(result: MethodChannel.Result, message: String) =
        Handler(Looper.getMainLooper()).post { result.success(message) }

    private fun postError(result: MethodChannel.Result, code: String, message: String) =
        Handler(Looper.getMainLooper()).post { result.error(code, message, null) }
}
