import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What a day mark of the week tile shows.
enum _Mark {
  /// A finished day that stayed under its target.
  under,

  /// A finished day over its target.
  over,

  /// A pause day, which counts nothing.
  pause,

  /// Today, still running.
  today,

  /// A day still to come.
  planned,

  /// A day the selected day's numbers do not cover.
  open,
}

/// The seven days of the run week as marks: under or over the target,
/// pause, today, or planned. The selected day's mark is bigger.
class DiaryWeekTileStrip extends ConsumerWidget {
  /// Creates the strip of the run week starting on [weekStart].
  const new({
    required this.data,
    required this.weekStart,
    required this.today,
    super.key,
  });

  /// Budget card data of the selected day.
  final DiaryBudgetCardData data;

  /// First day of the run week.
  final DateTime weekStart;

  /// Today.
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = [
      for (var i = 0; i < calorieGoalRunLengthDays; i++)
        addLocalDays(normalizeLocalDay(weekStart), i),
    ];
    final types = [
      for (final day in days)
        ref.watch(diaryDayTypeStatusProvider(day))?.type ?? DiaryDayType.normal,
    ];

    return Row(
      spacing: AppSpacing.xxs,
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: _Day(
              day: days[i],
              isSelected: isSameLocalDay(days[i], data.day),
              mark: _markOf(days[i], types[i]),
              isTraining: types[i] == DiaryDayType.training,
            ),
          ),
      ],
    );
  }

  _Mark _markOf(DateTime day, DiaryDayType type) {
    final normalizedToday = normalizeLocalDay(today);
    if (isSameLocalDay(day, data.day)) {
      if (data.isPauseDay) return _Mark.pause;
      return switch (data.status) {
        DiaryDayStatus.past => data.isOver ? _Mark.over : _Mark.under,
        DiaryDayStatus.today => _Mark.today,
        _ => _Mark.planned,
      };
    }
    if (type == DiaryDayType.pause) return _Mark.pause;
    if (isSameLocalDay(day, normalizedToday)) return _Mark.today;
    if (day.isAfter(normalizedToday)) return _Mark.planned;
    for (final previous
        in data.budgetDetails?.previousDays ??
            const <DiaryCarryoverDayDetail>[]) {
      if (isSameLocalDay(previous.date, day)) {
        if (previous.isPauseDay) return _Mark.pause;
        return previous.differenceKcal.round() < 0 ? _Mark.over : _Mark.under;
      }
    }
    return _Mark.open;
  }
}

class _Day extends StatelessWidget {
  const new({
    required this.day,
    required this.isSelected,
    required this.mark,
    required this.isTraining,
  });

  final DateTime day;
  final bool isSelected;
  final _Mark mark;
  final bool isTraining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // German short weekdays end with a dot, which the strip leaves out.
    final weekday = DateFormat.E(locale).format(day).replaceAll('.', '');
    final state = switch (mark) {
      _Mark.under => l10n.diaryWeekTileDayUnder,
      _Mark.over => l10n.diaryWeekTileDayOver,
      _Mark.pause => diaryDayTypeLabel(DiaryDayType.pause, l10n),
      _Mark.today => l10n.diaryWeekTileDayToday,
      _Mark.planned => l10n.diaryWeekTileDayPlanned,
      _Mark.open => l10n.diaryWeekTileDayOpen,
    };

    return Semantics(
      selected: isSelected,
      label: l10n.diaryWeekTileDaySemantics(
        DateFormat.EEEE(locale).format(day),
        state,
      ),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xxs,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              weekday,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: AppFonts.geist,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? colors.ink : colors.muted,
              ),
            ),
          ),
          SizedBox.square(
            dimension: AppDashboard.weekMarkSelected,
            child: Center(
              child: _MarkDot(
                mark: mark,
                isTraining: isTraining,
                isSelected: isSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkDot extends StatelessWidget {
  const new({
    required this.mark,
    required this.isTraining,
    required this.isSelected,
  });

  final _Mark mark;
  final bool isTraining;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final error = Theme.of(context).colorScheme.error;
    Border outline(Color color) =>
        Border.all(color: color, width: AppDashboard.weekMarkOutline);
    final (Color? fill, Border? border) = switch (mark) {
      _Mark.under => (colors.accentText, null),
      _Mark.over => (error, null),
      _Mark.pause || _Mark.open => (colors.track, null),
      _Mark.today => (colors.track, outline(colors.ink)),
      _Mark.planned => (null, outline(isTraining ? colors.ink : colors.muted)),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border,
      ),
      child: SizedBox.square(
        dimension: isSelected
            ? AppDashboard.weekMarkSelected
            : AppDashboard.weekMark,
        child: mark == _Mark.pause
            ? Icon(
                Icons.pause_rounded,
                size: AppDashboard.weekMarkIcon,
                color: colors.muted,
              )
            : null,
      ),
    );
  }
}
