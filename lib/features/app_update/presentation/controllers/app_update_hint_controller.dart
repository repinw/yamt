import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'app_update_hint_controller.g.dart';

const _shownVersionKey = 'app_update_hint_shown_version_v1';

/// The newer version that the "update available" hint still has to name,
/// or null. The hint shows once per newer version on this device.
@riverpod
class AppUpdateHintController extends _$AppUpdateHintController {
  @override
  Future<AppVersion?> build() async {
    final status = ref.watch(appUpdateStatusProvider).value;
    if (status is! AppUpdateAvailable) {
      return null;
    }
    final shown = await ref
        .watch(appPreferencesProvider)
        .getString(_shownVersionKey);
    return shown == status.latestVersion.toString()
        ? null
        : status.latestVersion;
  }

  /// Records that the hint named [version], so it does not show again.
  /// A failed save only logs: the hint then shows once more on the next
  /// start.
  Future<void> markShown(AppVersion version) async {
    state = const AsyncData(null);
    final result = await AsyncValue.guard(() async {
      final saved = await ref
          .read(appPreferencesProvider)
          .setString(_shownVersionKey, version.toString());
      if (!saved) {
        throw StateError('The device did not save the shown version.');
      }
    });
    if (!ref.mounted) return;
    if (result case AsyncError(:final error, :final stackTrace)) {
      log(
        'Saving the shown update hint failed.',
        name: 'AppUpdate',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
