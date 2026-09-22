import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart' as plugin;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/home_widget/domain/home_widget_exceptions.dart';

part 'home_widget_plugin_bridge.g.dart';

/// Key native widget code reads the snapshot JSON from.
const homeWidgetSnapshotDataKey = 'diary_home_widget_snapshot';

/// Qualified Android widget-provider class name `updateWidget` targets.
///
/// Must match `HomeDiaryWidgetReceiver`'s package and class name under
/// `android/app/src/main/kotlin/`.
const homeWidgetAndroidProviderName =
    'de.yamt.app.homewidget.HomeDiaryWidgetReceiver';

/// Talks to the native home-screen widget through the `home_widget` plugin:
/// stores the snapshot, asks for a redraw, and reports widget taps.
class HomeWidgetPluginBridge {
  /// Creates the plugin bridge.
  const new();

  /// Persists [snapshotJson] for native widget code and redraws the widget.
  ///
  /// Throws [HomeWidgetSyncFailedException] when the platform call fails.
  Future<void> saveSnapshot(String snapshotJson) async {
    try {
      await plugin.HomeWidget.saveWidgetData<String>(
        homeWidgetSnapshotDataKey,
        snapshotJson,
      );
      await plugin.HomeWidget.updateWidget(
        qualifiedAndroidName: homeWidgetAndroidProviderName,
      );
    } on PlatformException catch (error) {
      throw HomeWidgetSyncFailedException(error);
    } on MissingPluginException catch (error) {
      throw HomeWidgetSyncFailedException(error);
    }
  }

  /// URI the app was cold-launched with from a widget tap, else `null`.
  Future<Uri?> loadInitialLaunchUri() {
    return plugin.HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// URIs of widget taps while the app keeps running.
  Stream<Uri?> watchClicks() => plugin.HomeWidget.widgetClicked;
}

/// Provides the [HomeWidgetPluginBridge].
@Riverpod(keepAlive: true)
HomeWidgetPluginBridge homeWidgetPluginBridge(Ref ref) {
  return const HomeWidgetPluginBridge();
}
