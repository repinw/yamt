import 'dart:async';

import 'package:yamt/features/home_widget/data/home_widget_plugin_bridge.dart';
import 'package:yamt/features/home_widget/domain/home_widget_exceptions.dart';

/// In-memory [HomeWidgetPluginBridge] for tests.
class FakeHomeWidgetPluginBridge implements HomeWidgetPluginBridge {
  /// Creates the fake; [initialLaunchUri] is the cold-launch widget uri.
  new({this.initialLaunchUri, this.failSave = false});

  /// Uri returned by [loadInitialLaunchUri].
  final Uri? initialLaunchUri;

  /// Whether [saveSnapshot] throws like a failing platform call.
  final bool failSave;

  /// Snapshots passed to [saveSnapshot], in order.
  final List<String> savedSnapshots = [];

  final StreamController<Uri?> _clicks = StreamController<Uri?>.broadcast();

  /// Emits a widget tap while the app runs.
  void click(Uri? uri) => _clicks.add(uri);

  /// Closes the click stream.
  Future<void> dispose() => _clicks.close();

  @override
  Future<void> saveSnapshot(String snapshotJson) async {
    if (failSave) {
      throw HomeWidgetSyncFailedException(StateError('platform down'));
    }
    savedSnapshots.add(snapshotJson);
  }

  @override
  Future<Uri?> loadInitialLaunchUri() async => initialLaunchUri;

  @override
  Stream<Uri?> watchClicks() => _clicks.stream;
}
