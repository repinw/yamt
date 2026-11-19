import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Calls back when a recurring entry may have become due while the list
/// controller lives for the whole session: when the app comes back and when
/// the calendar day changes. One lifecycle listener and one timer per
/// controller.
class ShoppingListRenewal {
  Timer? _dayTimer;
  AppLifecycleListener? _lifecycle;

  /// Starts watching from a provider's build, after stopping an earlier
  /// start; [now] reads the clock and [onMayBeDue] runs on every trigger.
  void start(
    Ref ref, {
    required DateTime Function() now,
    required void Function() onMayBeDue,
  }) {
    _stop();
    _lifecycle = AppLifecycleListener(onResume: onMayBeDue);
    void armDayTimer() {
      final current = now();
      final nextDay = DateTime(current.year, current.month, current.day + 1);
      _dayTimer = Timer(nextDay.difference(current), () {
        onMayBeDue();
        armDayTimer();
      });
    }

    armDayTimer();
    ref.onDispose(_stop);
  }

  void _stop() {
    _dayTimer?.cancel();
    _dayTimer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}
