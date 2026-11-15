package de.yamt.app

import android.annotation.SuppressLint
import android.app.UiModeManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var dartListens = false
    private var heldShare: Intent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // The system recreates this activity with the intent that started its
        // task; that share was already handled. New shares come via onNewIntent,
        // which reaches Dart only once it listens (see below).
        val recreated = savedInstanceState != null ||
            intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        if (recreated && intent.isShare()) {
            intent = Intent(Intent.ACTION_MAIN).setClass(this, MainActivity::class.java)
        }
        super.onCreate(savedInstanceState)
    }

    // The share plugin drops a share that arrives before Dart listens to its
    // stream, as when the system recreates this activity for that share. So
    // the share waits here until Dart says it listens.
    @SuppressLint("MissingSuperCall")
    override fun onNewIntent(intent: Intent) {
        if (!dartListens && intent.isShare()) {
            heldShare = intent
            return
        }
        super.onNewIntent(intent)
    }

    private fun Intent.isShare() =
        action == Intent.ACTION_SEND || action == Intent.ACTION_SEND_MULTIPLE

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        KeyBackupChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.yamt.app/share_ready")
            .setMethodCallHandler { _, result ->
                dartListens = true
                heldShare?.let { flutterEngine.activityControlSurface.onNewIntent(it) }
                heldShare = null
                result.success(null)
            }
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
