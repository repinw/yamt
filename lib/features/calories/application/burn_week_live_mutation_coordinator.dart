import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'burn_week_live_mutation_coordinator.g.dart';

/// Keeps track of in-flight Burn Week live mutations to prevent duplicates.
@riverpod
BurnWeekLiveMutationCoordinator burnWeekLiveMutationCoordinator(Ref ref) {
  return BurnWeekLiveMutationCoordinator();
}

/// Coordinates queued and in-flight Burn Week mutations.
class BurnWeekLiveMutationCoordinator {
  _PendingBurnWeekMutationState? _pendingMutation;

  /// Whether a mutation with this key is currently queued or in flight.
  bool hasPendingMutation(String key) {
    return _pendingMutation?.key == key;
  }

  /// Queues a mutation to execute in a microtask, deduplicating identical work.
  void queueMutation({
    required String key,
    required Future<void> Function() action,
  }) {
    if (hasPendingMutation(key)) {
      return;
    }
    _pendingMutation = _QueuedBurnWeekMutationState(key);
    scheduleMicrotask(() {
      final pending = _pendingMutation;
      if (pending is! _QueuedBurnWeekMutationState || pending.key != key) {
        return;
      }
      _pendingMutation = _RunningBurnWeekMutationState(key);
      unawaited(_runMutation(key, action));
    });
  }

  Future<void> _runMutation(String key, Future<void> Function() action) async {
    try {
      await action();
    } finally {
      final pending = _pendingMutation;
      if (pending is _RunningBurnWeekMutationState && pending.key == key) {
        _pendingMutation = null;
      }
    }
  }
}

sealed class _PendingBurnWeekMutationState {
  const new(this.key);

  final String key;
}

class _QueuedBurnWeekMutationState extends _PendingBurnWeekMutationState {
  const new(super.key);
}

class _RunningBurnWeekMutationState extends _PendingBurnWeekMutationState {
  const new(super.key);
}
