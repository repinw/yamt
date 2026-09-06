import 'dart:async';

import 'package:flutter/material.dart';

/// Animates a confirmed intake change using the shared feedback start time.
/// Ordinary updates and already completed transitions render immediately.
class DiaryMacroTransition extends StatefulWidget {
  /// Creates a transition without imposing a layout on its caller.
  const DiaryMacroTransition({
    required this.current,
    required this.builder,
    this.previous,
    this.startedAt,
    super.key,
  });

  /// Final recorded intake.
  final double current;

  /// Intake excluding the foods recorded in this session.
  final double? previous;

  /// Shared timestamp for the feedback card and visible daily bars.
  final DateTime? startedAt;

  /// Builds the existing layout with animated intake and highlight opacity.
  final Widget Function(BuildContext context, double value, double highlight)
  builder;

  @override
  State<DiaryMacroTransition> createState() => _DiaryMacroTransitionState();
}

class _DiaryMacroTransitionState extends State<DiaryMacroTransition>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1,
  );
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    _synchronize();
  }

  @override
  void didUpdateWidget(DiaryMacroTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt ||
        oldWidget.previous != widget.previous ||
        oldWidget.current != widget.current) {
      _synchronize();
    }
  }

  void _synchronize() {
    final start = widget.startedAt;
    final elapsed = start == null
        ? 1400
        : DateTime.now().difference(start).inMilliseconds;
    if (_reduced == true || widget.previous == null || elapsed >= 1400) {
      _controller
        ..stop()
        ..value = 1;
      return;
    }
    unawaited(_controller.forward(from: (elapsed / 1400).clamp(0.0, 1.0)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final progress = Curves.easeOutCubic.transform(
        (_controller.value * 2).clamp(0.0, 1.0),
      );
      final previous = widget.previous ?? widget.current;
      return widget.builder(
        context,
        previous + (widget.current - previous) * progress,
        1 - _controller.value,
      );
    },
  );
}
