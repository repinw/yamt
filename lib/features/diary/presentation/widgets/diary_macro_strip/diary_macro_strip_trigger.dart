import 'package:flutter/widgets.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_overlay.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_stage.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars_content.dart';

/// Zero-height sliver placed directly above the daily card that sets [stage]
/// from how much of the card is under the pinned top bar.
///
/// The viewport lays it out on every scroll frame, so no scroll events are
/// needed.
class DiaryMacroStripTrigger extends StatefulWidget {
  /// Creates the trigger sliver.
  const new({required this.anchors, required this.stage, super.key});

  /// Keys of the daily card parts.
  final DiaryMacroStripAnchors anchors;

  /// Receives the current stage.
  final ValueNotifier<DiaryMacroStripStage> stage;

  @override
  State<DiaryMacroStripTrigger> createState() => _DiaryMacroStripTriggerState();
}

class _DiaryMacroStripTriggerState extends State<DiaryMacroStripTrigger> {
  double _coveredCardExtent = 0;
  bool _updateScheduled = false;

  @override
  void didUpdateWidget(DiaryMacroStripTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another day can change the card without changing the scroll position.
    _scheduleUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Part of the card above the viewport plus the part under the bar.
        _coveredCardExtent = constraints.scrollOffset + constraints.overlap;
        _scheduleUpdate();
        return const SliverToBoxAdapter();
      },
    );
  }

  /// Card parts are measured after layout, when their sizes are final.
  void _scheduleUpdate() {
    if (_updateScheduled) {
      return;
    }
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (mounted) {
        widget.stage.value = _resolveStage();
      }
    });
  }

  DiaryMacroStripStage _resolveStage() {
    final covered = _coveredCardExtent;
    final card = _attachedBox(widget.anchors.card);
    if (card == null) {
      // The lazy list drops the card once it is far above the viewport.
      return covered > 0
          ? DiaryMacroStripStage.full
          : DiaryMacroStripStage.hidden;
    }
    final kcalBarTop = _edgeWithin(widget.anchors.kcalBar, card);
    if (kcalBarTop == null || covered < kcalBarTop) {
      return DiaryMacroStripStage.hidden;
    }
    final fatRowTop = _fatRowTopWithin(card) ?? card.size.height;
    final kcalRow = _attachedBox(widget.anchors.stripKcalRow);
    if (kcalRow == null) {
      // The row is built once the kcal stage is shown; check again then.
      _scheduleUpdate();
      return DiaryMacroStripStage.kcal;
    }
    // The strip's kcal row covers this much of the card below the top bar.
    final kcalRowExtent = kcalRow.size.height + diaryMacroStripKcalRowInset;
    return covered + kcalRowExtent >= fatRowTop
        ? DiaryMacroStripStage.full
        : DiaryMacroStripStage.kcal;
  }

  double? _edgeWithin(GlobalKey key, RenderBox card) {
    final box = _attachedBox(key);
    if (box == null) {
      return null;
    }
    return box.localToGlobal(Offset.zero, ancestor: card).dy;
  }

  /// Top of the last of the three equally tall macro rows (fat).
  double? _fatRowTopWithin(RenderBox card) {
    final box = _attachedBox(widget.anchors.macroBars);
    final top = _edgeWithin(widget.anchors.macroBars, card);
    if (box == null || top == null) {
      return null;
    }
    final rowExtent = (box.size.height - 2 * diaryMacroRowGap) / 3;
    return top + box.size.height - rowExtent;
  }

  RenderBox? _attachedBox(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }
}
