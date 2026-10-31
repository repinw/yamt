import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/diary_day_type_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_toggle_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The seven days of the run week with their day types. A tap switches a
/// day between normal and training. A pause day only shows: the pause button
/// of the card sets and removes it (#921).
class DiaryBudgetWeekStrip extends ConsumerWidget {
  /// Creates the strip of the run week starting on [weekStart].
  const new({
    required this.weekStart,
    required this.selectedDay,
    required this.today,
    super.key,
  });

  /// First day of the run week.
  final DateTime weekStart;

  /// Day of the card, marked with a ring.
  final DateTime selectedDay;

  /// Today; later days are drawn as plans.
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final days = [
      for (var i = 0; i < calorieGoalRunLengthDays; i++)
        addLocalDays(normalizeLocalDay(weekStart), i),
    ];
    final types = [
      for (final day in days)
        ref.watch(diaryDayTypeStatusProvider(day))?.type ?? DiaryDayType.normal,
    ];
    final trainingDays = types.where((t) => t == DiaryDayType.training).length;
    final small = textTheme.bodySmall?.copyWith(
      fontFamily: AppFonts.geist,
      color: colors.muted,
    );

    return DecoratedBox(
      key: DiaryBudgetCardKeys.weekStrip,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppBudgetCard.boxRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.diaryBudgetWeekTitle,
                    style: small?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  l10n.diaryBudgetTrainingDayCount(trainingDays),
                  style: small,
                ),
              ],
            ),
            Row(
              spacing: AppBudgetCard.weekDayGap,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: _WeekDay(
                      key: DiaryBudgetCardKeys.weekDay(i),
                      day: days[i],
                      type: types[i],
                      isSelected: isSameLocalDay(days[i], selectedDay),
                      isFuture: days[i].isAfter(normalizeLocalDay(today)),
                      onTap: switch (_toggled(types[i])) {
                        final type? => () => unawaited(
                          selectDiaryDayTypeFlow(
                            context,
                            ref,
                            day: days[i],
                            type: type,
                          ),
                        ),
                        null => null,
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The type a tap switches [type] to, or `null` for a pause day.
  DiaryDayType? _toggled(DiaryDayType type) => switch (type) {
    DiaryDayType.normal => DiaryDayType.training,
    DiaryDayType.training => DiaryDayType.normal,
    DiaryDayType.pause => null,
  };
}

class _WeekDay extends StatelessWidget {
  const new({
    required this.day,
    required this.type,
    required this.isSelected,
    required this.isFuture,
    required this.onTap,
    super.key,
  });

  final DateTime day;
  final DiaryDayType type;
  final bool isSelected;
  final bool isFuture;

  /// `null` for a day the strip cannot switch.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // German short weekdays end with a dot, which the strip leaves out.
    final weekday = DateFormat.E(locale).format(day).replaceAll('.', '');
    final isTraining = type == DiaryDayType.training;
    final foreground = isTraining && !isFuture ? colors.tile : colors.muted;

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label:
          (onTap == null
          ? l10n.diaryBudgetWeekPauseDaySemantics
          : l10n.diaryBudgetWeekDaySemantics)(
            DateFormat.EEEE(locale).format(day),
            diaryDayTypeLabel(type, l10n),
          ),
      onTap: onTap,
      excludeSemantics: true,
      child: AppInkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Column(
            spacing: AppSpacing.xxs,
            children: [
              Text(
                weekday,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: AppFonts.geist,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? colors.ink : colors.muted,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFuture
                      ? Colors.transparent
                      : isTraining
                      ? colors.ink
                      : colors.track,
                  border: isFuture
                      ? Border.all(
                          color: isTraining ? colors.ink : colors.muted,
                          width: AppBudgetCard.chipOutline,
                        )
                      : null,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: colors.accentText,
                            width: AppBudgetCard.weekSelectedRing,
                          )
                        : null,
                  ),
                  child: SizedBox.square(
                    dimension: AppBudgetCard.dayButton,
                    child: Icon(
                      diaryBudgetDayTypeIcon(type),
                      size: AppBudgetCard.dayIcon,
                      color: isFuture && isTraining ? colors.ink : foreground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
