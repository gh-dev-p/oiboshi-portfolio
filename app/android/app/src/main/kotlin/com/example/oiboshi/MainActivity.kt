package com.example.oiboshi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createLiveNotificationChannel()
    }

    /**
     * 配信開始の通知のチャンネル（機能仕様書 4.3.3）。サーバーは、このチャンネルの ID で送る
     * （`supabase/functions/_shared/fcm.ts` の `ANDROID_CHANNEL_ID`）。名前は、端末の言語で付け直す。
     */
    private fun createLiveNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            LIVE_CHANNEL_ID,
            getString(R.string.live_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.live_notification_channel_description)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        private const val LIVE_CHANNEL_ID = "live_start"
    }
}
