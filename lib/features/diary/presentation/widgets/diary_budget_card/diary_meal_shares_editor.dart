import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_shares_blocks.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_time_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sets the parts of the day: framed blocks with a handle on each border
/// that drags it, below them when the day starts and each meal with its
/// share, kcal and the time it is eaten by, and a reset to the standard
/// split and times.
class DiaryMealSharesEditor extends ConsumerStatefulWidget {
  /// Creates the editor.
  const new({required this.targetKcal, super.key});

  /// The day's kcal target the shares split; at 0 the rows show only the
  /// shares.
  final double targetKcal;

  /// Key of the draggable blocks.
  static const blocksKey = ValueKey<String>('diary-meal-shares-blocks');

  /// Key of the reset button.
  static const resetKey = ValueKey<String>('diary-meal-shares-reset');

  /// Key of the share and kcal of [meal].
  static ValueKey<String> partKey(MealType meal) =>
      ValueKey<String>('diary-meal-shares-part-${meal.name}');

  /// Key of the button with the time the day starts.
  static const startKey = ValueKey<String>('diary-meal-shares-start');

  /// Key of the button with the time [meal] is eaten by.
  static ValueKey<String> timeKey(MealType meal) =>
      ValueKey<String>('diary-meal-shares-time-${meal.name}');

  @override
  ConsumerState<DiaryMealSharesEditor> createState() =>
      _DiaryMealSharesEditorState();
}

class _DiaryMealSharesEditorState extends ConsumerState<DiaryMealSharesEditor> {
  // The shares while a handle is dragged; saved when it is let go.
  DiaryMealShares? _dragged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saved = ref.watch(diaryMealSharesControllerProvider);
    final shares = _dragged ?? saved;
    final times = ref.watch(diaryMealTimesControllerProvider);
    final kcal = shares.splitKcal(widget.targetKcal);
    void changeTimes(DiaryMealTimes Function(DiaryMealTimes) change) =>
        unawaited(
          ref
              .read(diaryMealTimesControllerProvider.notifier)
              .select(change(ref.read(diaryMealTimesControllerProvider))),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        DiaryMealSharesBlocks(
          key: DiaryMealSharesEditor.blocksKey,
          shares: shares,
          onChanged: (dragged) => setState(() => _dragged = dragged),
          onChangeEnd: (changed) {
            setState(() => _dragged = null);
            unawaited(
              ref
                  .read(diaryMealSharesControllerProvider.notifier)
                  .select(changed),
            );
          },
        ),
        _Row(
          name: l10n.diaryMealTimesDayStart,
          time: DiaryMealTimeButton(
            key: DiaryMealSharesEditor.startKey,
            minute: times.start,
            label: l10n.diaryMealTimesFrom,
            onPicked: (minute) =>
                changeTimes((times) => times.withStart(minute)),
          ),
        ),
        for (final (i, meal) in MealType.sectionOrder.indexed)
          _Row(
            name: meal.localizedName(l10n),
            part: _part(l10n, shares.of(meal), kcal[i]),
            partKey: DiaryMealSharesEditor.partKey(meal),
            isOff: shares.of(meal) == 0,
            time: DiaryMealTimeButton(
              key: DiaryMealSharesEditor.timeKey(meal),
              minute: times.endOf(meal),
              label: l10n.diaryMealTimesBy,
              onPicked: (minute) =>
                  changeTimes((times) => times.withEnd(meal, minute)),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: DiaryMealSharesEditor.resetKey,
            onPressed: () {
              unawaited(
                ref.read(diaryMealSharesControllerProvider.notifier).reset(),
              );
              unawaited(
                ref.read(diaryMealTimesControllerProvider.notifier).reset(),
              );
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.diaryMealSharesReset),
          ),
        ),
      ],
    );
  }

  /// A meal's [share] in words, with its [kcal] when the day has a target.
  String _part(AppLocalizations l10n, double share, int kcal) {
    final percent = (share * 100).round().toString();
    if (share == 0) return l10n.diaryMealSharesOff;
    if (widget.targetKcal <= 0) return l10n.diaryMealSharesPercent(percent);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return l10n.diaryMealSharesPart(percent, format.format(kcal));
  }
}

/// A row of the editor: a name, a meal's share when it has one, and a time
/// button; a screen reader reads it as one.
class _Row extends StatelessWidget {
  const new({
    required this.name,
    required this.time,
    this.part,
    this.partKey,
    this.isOff = false,
  });

  final String name;
  final Widget time;
  final String? part;
  final Key? partKey;
  final bool isOff;

  /// The text scale above which a row takes two lines.
  static const double _largeText = 1.3;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: isOff ? FoodLabelColors.of(context).muted : null);
    final label = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        Text(name, style: style),
        if (part case final part?)
          Text(
            part,
            key: partKey,
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
    // With large text the time moves below the name and the share.
    final isLarge = MediaQuery.textScalerOf(context).scale(1) > _largeText;
    return MergeSemantics(
      child: isLarge
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label,
                Align(alignment: AlignmentDirectional.centerEnd, child: time),
              ],
            )
          : Row(
              children: [
                Expanded(child: label),
                time,
              ],
            ),
    );
  }
}
