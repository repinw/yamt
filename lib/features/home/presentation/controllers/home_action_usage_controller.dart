import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/home/data/home_action_usage_repository.dart';

part 'home_action_usage_controller.g.dart';

/// Counts how often each action of the home action panel was tapped on this
/// device, so the panel can mark the most used one.
@riverpod
class HomeActionUsageController extends _$HomeActionUsageController {
  @override
  Map<String, int> build() {
    return ref.watch(homeActionUsageRepositoryProvider).cachedCounts();
  }

  /// Counts one tap on the action [id]. Returns `false` when the count could
  /// not be saved; it still counts until the app restarts.
  Future<bool> record(String id) async {
    final next = Map<String, int>.unmodifiable({
      ...state,
      id: (state[id] ?? 0) + 1,
    });
    state = next;
    try {
      await ref.read(homeActionUsageRepositoryProvider).saveCounts(next);
      return true;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to save the home action usage counts.',
        name: 'HomeActionUsageController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
