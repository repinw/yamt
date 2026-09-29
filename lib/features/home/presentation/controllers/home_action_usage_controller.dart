import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'home_action_usage_controller.g.dart';

const _preferenceKey = 'home_action_usage_counts';

/// Counts how often each action of the home action panel was tapped on this
/// device, so the panel can mark the most used one.
@riverpod
class HomeActionUsageController extends _$HomeActionUsageController {
  @override
  Map<String, int> build() {
    final stored = ref
        .read(appPreferencesProvider)
        .getStringSync(_preferenceKey);
    if (stored == null) {
      return const <String, int>{};
    }
    return Map.unmodifiable(
      (jsonDecode(stored) as Map<String, dynamic>).cast<String, int>(),
    );
  }

  /// Counts one tap on the action [id].
  Future<void> record(String id) async {
    final next = Map<String, int>.unmodifiable({
      ...state,
      id: (state[id] ?? 0) + 1,
    });
    state = next;
    await ref
        .read(appPreferencesProvider)
        .setString(_preferenceKey, jsonEncode(next));
  }
}
