import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

part 'progress_weight_health_hint_controller.g.dart';

const _dismissedKey = 'progress_weight_health_hint_dismissed_v1';

/// Whether the weight list still shows the large card that connects Health.
/// Once a user dismissed it on this device, the page shows them a small icon
/// instead.
@riverpod
class ProgressWeightHealthHintController
    extends _$ProgressWeightHealthHintController {
  late String _key;

  @override
  bool build() {
    final uid = ref.watch(authStateChangesProvider).asData?.value?.uid;
    _key = '$_dismissedKey:${uid ?? 'local'}';
    return ref.watch(appPreferencesProvider).getStringSync(_key) == null;
  }

  /// Hides the card for good.
  Future<void> dismiss() async {
    state = false;
    try {
      await ref.read(appPreferencesProvider).setString(_key, 'true');
    } on Object catch (error, stackTrace) {
      // The card stays hidden until the page opens again.
      log(
        'Failed to store the dismissed Health card.',
        name: 'ProgressWeightHealthHintController',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
