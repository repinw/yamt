import 'dart:async';

import 'package:flutter/services.dart';

/// Central app haptic helpers for confirmed interactive callbacks.
abstract final class AppHapticFeedback {
  /// Progress ratio from which a rising pulse stops being a light tick.
  static const _mediumImpactThreshold = 0.35;

  /// Progress ratio from which a rising pulse turns medium.
  static const _heavyImpactThreshold = 0.7;

  /// Sends a small haptic pulse without awaiting the platform channel.
  static void lightImpact() {
    unawaited(HapticFeedback.lightImpact());
  }

  /// Sends a rotary tick selection haptic pulse without awaiting.
  static void selectionClick() {
    unawaited(HapticFeedback.selectionClick());
  }

  /// Sends a medium haptic pulse without awaiting.
  static void mediumImpact() {
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Sends a heavy haptic pulse without awaiting.
  static void heavyImpact() {
    unawaited(HapticFeedback.heavyImpact());
  }

  /// Sends a pulse that grows stronger the further [step] is through [total].
  ///
  /// Used to build tension while the user walks through a guided flow.
  static void risingImpact(int step, int total) {
    if (total <= 0) {
      lightImpact();
      return;
    }
    final ratio = (step / total).clamp(0.0, 1.0);
    if (ratio < _mediumImpactThreshold) {
      selectionClick();
      return;
    }
    if (ratio < _heavyImpactThreshold) {
      lightImpact();
      return;
    }
    if (ratio < 1) {
      mediumImpact();
      return;
    }
    heavyImpact();
  }

  /// Wraps a callback with a small haptic pulse.
  static VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) {
      return null;
    }

    return () {
      lightImpact();
      callback();
    };
  }

  /// Wraps a value callback with a small haptic pulse.
  static ValueChanged<T>? wrapValueChanged<T>(ValueChanged<T>? callback) {
    if (callback == null) {
      return null;
    }

    return (value) {
      lightImpact();
      callback(value);
    };
  }
}
