import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/features/progress/domain/progress_day.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_segment_bar.dart';

/// One day of the week: weekday, day type, the day bar, and the eaten kcal.
class ProgressDayRow extends StatelessWidget {
  /// Creates a day row.
  const new({required this.day, required this.isToday, super.key});

  /// The day to show.
  final ProgressDay day;

  /// Whether [day] is today; its weekday is underlined.
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final isOver = !day.isFuture && day.eatenKcal > day.goalKcal;
    final type = day.isPauseDay
        ? DiaryDayType.pause
        : day.isTrainingDay
        ? DiaryDayType.training
        : DiaryDayType.rest;
    return Opacity(
      opacity: day.isFuture ? AppProgress.futureOpacity : 1,
      child: Row(
        children: [
          SizedBox(
            width: AppProgress.dayLabelWidth,
            child: Text(
              DateFormat.E(locale).format(day.day),
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
                decoration: isToday ? TextDecoration.underline : null,
              ),
            ),
          ),
          SizedBox(
            width: AppProgress.dayTypeWidth,
            child: Text(
              diaryDayTypeEmoji(type),
              textAlign: TextAlign.center,
              style: textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: ProgressSegmentBar.day(day)),
          SizedBox(
            width: AppProgress.dayValueWidth,
            child: Text(
              day.isFuture
                  ? '–'
                  : NumberFormat.decimalPattern(locale)
                        .format(day.eatenKcal.round()),
              textAlign: TextAlign.end,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isOver ? colors.low : colors.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
