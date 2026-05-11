import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Adds a small haptic pulse for completed touch taps across the app.
///
/// Material widget feedback is disabled in the app theme and raw Ink widgets so
/// this remains the single feedback source for tap haptics.
class AppHapticFeedback extends StatefulWidget {
  /// Creates an app-wide haptic feedback listener.
  const AppHapticFeedback({required this.child, super.key});

  /// Content that should receive haptic tap feedback.
  final Widget child;

  @override
  State<AppHapticFeedback> createState() => _AppHapticFeedbackState();
}

class _AppHapticFeedbackState extends State<AppHapticFeedback> {
  final Map<int, _TrackedTouchPress> _activePresses = {};

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _activePresses.clear();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isTouchPress(event.kind) || event.buttons != kPrimaryButton) {
      return;
    }

    _activePresses[event.pointer] = _TrackedTouchPress(event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final press = _activePresses[event.pointer];
    if (press == null || press.movedTooFar) {
      return;
    }

    if ((event.position - press.startPosition).distance > kTouchSlop) {
      press.movedTooFar = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final press = _activePresses.remove(event.pointer);
    if (press == null || press.movedTooFar) {
      return;
    }

    unawaited(HapticFeedback.lightImpact());
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePresses.remove(event.pointer);
  }

  bool _isTouchPress(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }
}

class _TrackedTouchPress {
  _TrackedTouchPress(this.startPosition);

  final Offset startPosition;
  bool movedTooFar = false;
}
