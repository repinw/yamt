import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_placeholder.dart';

/// Shows [child] only while [index] is the resting page or next to it, and a
/// [DiaryDayPlaceholder] otherwise.
///
/// [child] keeps its identity between switches, so it is not rebuilt when the
/// resting page moves elsewhere.
class DiaryRestingDayGate extends StatefulWidget {
  /// Creates the gate.
  const new({
    required this.index,
    required this.restingPage,
    required this.child,
    super.key,
  });

  /// Index of this page.
  final int index;

  /// Page the pager rests on.
  final ValueListenable<int> restingPage;

  /// Full content of the page.
  final Widget child;

  @override
  State<DiaryRestingDayGate> createState() => _DiaryRestingDayGateState();
}

class _DiaryRestingDayGateState extends State<DiaryRestingDayGate> {
  late bool _isNear = _resolveNear();

  @override
  void initState() {
    super.initState();
    widget.restingPage.addListener(_updateNear);
  }

  @override
  void didUpdateWidget(DiaryRestingDayGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restingPage != widget.restingPage) {
      oldWidget.restingPage.removeListener(_updateNear);
      widget.restingPage.addListener(_updateNear);
    }
    _isNear = _resolveNear();
  }

  @override
  void dispose() {
    widget.restingPage.removeListener(_updateNear);
    super.dispose();
  }

  bool _resolveNear() => (widget.restingPage.value - widget.index).abs() <= 1;

  void _updateNear() {
    final isNear = _resolveNear();
    if (isNear != _isNear) {
      setState(() => _isNear = isNear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isNear ? widget.child : const DiaryDayPlaceholder();
  }
}
