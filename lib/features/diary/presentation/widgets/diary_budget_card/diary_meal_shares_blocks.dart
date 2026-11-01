import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The parts of the day as framed blocks with a round handle on each
/// border, also on a border at the edge, so a meal at 0 can come back.
/// Dragging a handle moves its border in whole percent; a screen reader
/// moves it by [step] percent.
class DiaryMealSharesBlocks extends StatefulWidget {
  /// Creates the blocks.
  const new({
    required this.shares,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  /// The shares to show.
  final DiaryMealShares shares;

  /// Gets the shares while a handle is dragged.
  final ValueChanged<DiaryMealShares> onChanged;

  /// Gets the shares when a handle is let go or a screen reader moved a
  /// border.
  final ValueChanged<DiaryMealShares> onChangeEnd;

  /// Percent a screen reader moves a border by.
  static const int step = 5;

  @override
  State<DiaryMealSharesBlocks> createState() => _DiaryMealSharesBlocksState();
}

class _DiaryMealSharesBlocksState extends State<DiaryMealSharesBlocks> {
  int? _boundary;
  double _downX = 0;
  // The last dragged shares; a move and the lift can come in one frame.
  DiaryMealShares? _latest;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final shares = widget.shares;
    return LayoutBuilder(
      builder: (context, constraints) {
        // A handle on the edge still shows whole.
        const inset = AppBudgetCard.mealSharesHandle / 2;
        final width = constraints.maxWidth - 2 * inset;
        int percentAt(double dx) => ((dx - inset) / width * 100).round();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onHorizontalDragDown: (details) => _downX = details.localPosition.dx,
          onHorizontalDragStart: (details) => _boundary = shares.boundaryAt(
            percentAt(_downX),
            rightward: details.localPosition.dx >= _downX,
          ),
          onHorizontalDragCancel: () {
            _boundary = null;
            _latest = null;
          },
          onHorizontalDragUpdate: (details) {
            final boundary = _boundary;
            if (boundary == null) return;
            final moved = (_latest ?? shares).moveBoundary(
              boundary,
              percentAt(details.localPosition.dx),
            );
            _latest = moved;
            widget.onChanged(moved);
          },
          onHorizontalDragEnd: (_) {
            if (_boundary == null) return;
            _boundary = null;
            final latest = _latest ?? widget.shares;
            _latest = null;
            widget.onChangeEnd(latest);
          },
          // The strip is as high as a tap target; the blocks sit in it.
          child: SizedBox(
            height: AppSizes.minTapTarget,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      height: AppBudgetCard.mealSharesHandle,
                      child: _Blocks(
                        shares: shares,
                        frame: colors.muted,
                        handle: colors.ink,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < shares.boundaries.length; i++)
                  Positioned(
                    left: shares.boundaries[i] / 100 * width,
                    width: AppBudgetCard.mealSharesHandle,
                    top: 0,
                    bottom: 0,
                    child: _BorderSemantics(
                      shares: shares,
                      index: i,
                      onChanged: widget.onChangeEnd,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A border for a screen reader: a slider between the two meals it splits.
class _BorderSemantics extends StatelessWidget {
  const new({
    required this.shares,
    required this.index,
    required this.onChanged,
  });

  final DiaryMealShares shares;
  final int index;
  final ValueChanged<DiaryMealShares> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = shares.boundaries[index];
    final up = shares.moveBoundary(index, border + DiaryMealSharesBlocks.step);
    final down = shares.moveBoundary(
      index,
      border - DiaryMealSharesBlocks.step,
    );
    String value(DiaryMealShares of) => l10n.diaryMealSharesBorderValue(
      of.percents[index].toString(),
      of.percents[index + 1].toString(),
    );
    return Semantics(
      slider: true,
      label: l10n.diaryMealSharesBorder(
        MealType.sectionOrder[index].localizedName(l10n),
        MealType.sectionOrder[index + 1].localizedName(l10n),
      ),
      value: value(shares),
      increasedValue: value(up),
      decreasedValue: value(down),
      onIncrease: up == shares ? null : () => onChanged(up),
      onDecrease: down == shares ? null : () => onChanged(down),
      child: const SizedBox.expand(),
    );
  }
}

/// The framed blocks of [shares] with a round handle on each border.
class _Blocks extends StatelessWidget {
  const new({required this.shares, required this.frame, required this.handle});

  final DiaryMealShares shares;
  final Color frame;
  final Color handle;

  @override
  Widget build(BuildContext context) {
    const bar = AppBudgetCard.mealSharesBar;
    const knob = AppBudgetCard.mealSharesHandle;
    const gap = AppBudgetCard.mealBlockGap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - knob;
        final edges = [0, ...shares.boundaries, 100];
        double at(int percent) => knob / 2 + percent / 100 * width;
        return Stack(
          children: [
            for (var i = 1; i < edges.length; i++)
              if (edges[i] > edges[i - 1])
                Positioned(
                  left: at(edges[i - 1]) + (edges[i - 1] == 0 ? 0 : gap / 2),
                  width: math.max(
                    0,
                    at(edges[i]) -
                        at(edges[i - 1]) -
                        (edges[i - 1] == 0 ? 0 : gap / 2) -
                        (edges[i] == 100 ? 0 : gap / 2),
                  ),
                  top: (knob - bar) / 2,
                  height: bar,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: frame),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(bar / 2),
                      ),
                    ),
                  ),
                ),
            for (final border in shares.boundaries)
              Positioned(
                left: at(border) - knob / 2,
                top: 0,
                width: knob,
                height: knob,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: handle,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
