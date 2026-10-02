package pro.devlogs.stitch.lilo.wallpapers.hd

import android.content.Context
import android.content.SharedPreferences
import android.media.MediaPlayer
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder

/** Plays the app-selected, locally cached video as an Android live wallpaper. */
class VideoLiveWallpaperService : WallpaperService() {
    override fun onCreateEngine(): Engine = VideoEngine()

    inner class VideoEngine : Engine() {
        private var mediaPlayer: MediaPlayer? = null
        private var isPrepared = false
        private var isVisible = true

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            startPlayback(holder)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            super.onVisibilityChanged(visible)
            isVisible = visible
            val player = mediaPlayer ?: return
            if (!isPrepared) return

            try {
                if (visible) player.start() else player.pause()
            } catch (_: IllegalStateException) {
                // The surface is being replaced. onSurfaceCreated attaches a
                // player to the new surface.
            }
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            releasePlayer()
        }

        override fun onDestroy() {
            releasePlayer()
            super.onDestroy()
        }

        private fun startPlayback(holder: SurfaceHolder) {
            releasePlayer()
            val source = readSource(applicationContext) ?: return
            isPrepared = false

            mediaPlayer = MediaPlayer().apply {
                setSurface(holder.surface)
                setDataSource(source)
                isLooping = true
                setVolume(0f, 0f)
                setOnPreparedListener { player ->
                    isPrepared = true
                    if (isVisible) player.start()
                }
                setOnErrorListener { _, _, _ -> true }
                prepareAsync()
            }
        }

        private fun releasePlayer() {
            isPrepared = false
            // release() is sufficient; stop()/isPlaying() in an engine callback
            // can race the native surface transition.
            mediaPlayer?.release()
            mediaPlayer = null
        }
    }

    companion object {
        private const val preferencesName = "stitch_live_wallpaper"
        private const val sourceKey = "source"

        fun setSource(context: Context, path: String) {
            prefs(context).edit().putString(sourceKey, path).commit()
        }

        private fun readSource(context: Context): String? =
            prefs(context).getString(sourceKey, null)

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
    }
}
