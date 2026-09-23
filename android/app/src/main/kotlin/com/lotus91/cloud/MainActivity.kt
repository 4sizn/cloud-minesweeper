package com.lotus91.cloud

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.provider.Settings

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cloud_minesweeper/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openSettings") {
                    try {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                        result.success(null)
                    } catch (exception: Exception) {
                        result.error("unavailable", "Settings could not open", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
