import 'dart:async';

import 'package:flutter/services.dart';

/// Central app haptic helpers for confirmed interactive callbacks.
abstract final class AppHapticFeedback {
  /// Sends a small haptic pulse without awaiting the platform channel.
  static void lightImpact() {
    unawaited(HapticFeedback.lightImpact());
  }

  /// Sends a rotary tick selection haptic pulse without awaiting.
  static void selectionClick() {
    unawaited(HapticFeedback.selectionClick());
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
