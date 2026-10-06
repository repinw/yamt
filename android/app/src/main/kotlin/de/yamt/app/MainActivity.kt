package de.yamt.app

import android.app.UiModeManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        KeyBackupChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.yamt.app/theme_mode")
            .setMethodCallHandler { call, result ->
                if (call.method != "set") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // The system keeps this night mode for the app and draws the
                // launch screen of the next cold start in it. Before Android
                // 12 the launch screen follows the system brightness.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    getSystemService(UiModeManager::class.java).setApplicationNightMode(
                        when (call.arguments as? String) {
                            "light" -> UiModeManager.MODE_NIGHT_NO
                            "dark" -> UiModeManager.MODE_NIGHT_YES
                            else -> UiModeManager.MODE_NIGHT_AUTO
                        },
                    )
                }
                result.success(null)
            }
    }
}
