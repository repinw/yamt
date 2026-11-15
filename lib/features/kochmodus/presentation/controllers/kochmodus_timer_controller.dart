import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/kochmodus/application/cook_run_start_service.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_run_edits.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';

part 'kochmodus_timer_controller.g.dart';

/// Starts, extends and stops the timers of cooking the [KochmodusTarget];
/// each action is one change of the run (`KochmodusController.change`) and
/// returns whether it worked.
@riverpod
class KochmodusTimerController extends _$KochmodusTimerController {
  @override
  FutureOr<void> build(KochmodusTarget target) {
    // The run's controller lasts while a timer starts.
    ref.listen(kochmodusControllerProvider(target), (_, _) {});
  }

  /// Starts the timer [label] that rings after [duration] on this device;
  /// while a timer of that name still counts, as after a double tap, none
  /// starts (`cookRunWithTimer`).
  Future<bool> startTimer(String label, Duration duration) async {
    final link = ref.keepAlive();
    try {
      final timer = await ref
          .read(cookRunStartServiceProvider)
          .timer(label, duration);
      if (!ref.mounted) return false;
      final now = ref.read(clockProvider)();
      return await _cooking.change(
        (run) => cookRunWithTimer(run, timer, now: now),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to start a timer of the cook run.',
        name: 'KochmodusTimerController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      link.close();
    }
  }

  /// "+1 Min" on the timer [timerId], from now when it rang already.
  Future<bool> extendTimer(String timerId) {
    final now = ref.read(clockProvider)();
    return _cooking.change(
      (run) => run.extendTimer(timerId, kochmodusTimerExtension, now: now),
    );
  }

  /// Stops the timer [timerId] ("Stopp"); a timer that is gone already, as
  /// after a second tap, changes nothing.
  Future<bool> stopTimer(String timerId) => _cooking.change(
    (run) => run.timers.any((timer) => timer.id == timerId)
        ? run.stopTimer(timerId)
        : run,
  );

  KochmodusController get _cooking =>
      ref.read(kochmodusControllerProvider(target).notifier);
}
