import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/features/progress/application/progress_intake_provider.dart';
import 'package:yamt/features/progress/domain/progress_average.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Averages of training days against rest days over the last four weeks:
/// eaten kcal, protein, carbohydrates, and fat.
class ProgressDayTypeSection extends ConsumerWidget {
  /// Creates the comparison section.
  const new({super.key});

  /// Stable key of the section.
  static const sectionKey = ValueKey<String>('progress-day-type-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(progressIntakeProvider)
        .when(
          data: (intake) => _DayTypeContent(
            key: sectionKey,
            training: intake.training,
            rest: intake.rest,
          ),
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }
}

class _DayTypeContent extends StatelessWidget {
  const new({required this.training, required this.rest, super.key});

  final ProgressAverage training;
  final ProgressAverage rest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final macros = MetricAccentColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isEmpty = training.dayCount == 0 && rest.dayCount == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.progressDayTypeKicker.toUpperCase(),
          style: progressKickerStyle(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.progressDayTypeTitle,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isEmpty)
          ProgressSectionNote(text: l10n.progressDayTypeEmpty)
        else ...[
          Wrap(
            spacing: AppSpacing.xl,
            children: [
              for (final (type, average) in [
                (DiaryDayType.training, training),
                (DiaryDayType.rest, rest),
              ])
                Text(
                  l10n.progressDayTypeDays(
                    diaryDayTypeEmoji(type),
                    diaryDayTypeLabel(type, l10n),
                    average.dayCount,
                  ),
                  style: textTheme.labelMedium?.copyWith(color: colors.ink),
                ),
            ],
          ),
          for (final group in [
            (l10n.progressEaten, colors.ink, _eatenKcal, true),
            (l10n.caloriesProteinLabel, macros.protein, _protein, false),
            (l10n.caloriesCarbsLabel, macros.carbs, _carbs, false),
            (l10n.caloriesFatLabel, macros.fat, _fat, false),
          ]) ...[
            const SizedBox(height: AppSpacing.md),
            _CompareGroup(
              label: group.$1,
              color: group.$2,
              training: group.$3(training),
              rest: group.$3(rest),
              isKcal: group.$4,
            ),
          ],
        ],
      ],
    );
  }
}

double _eatenKcal(ProgressAverage average) => average.eatenKcal;
double _protein(ProgressAverage average) => average.proteinGrams;
double _carbs(ProgressAverage average) => average.carbsGrams;
double _fat(ProgressAverage average) => average.fatGrams;

class _CompareGroup extends StatelessWidget {
  const new({
    required this.label,
    required this.color,
    required this.training,
    required this.rest,
    required this.isKcal,
  });

  final String label;
  final Color color;
  final double training;
  final double rest;

  /// Whether the values are kcal; else grams.
  final bool isKcal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ink = FoodLabelColors.of(context).ink;
    final max = math.max(training, rest) * AppProgress.compareHeadroom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxs,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        _CompareBar(
          type: DiaryDayType.training,
          value: training,
          share: max <= 0 ? 0 : training / max,
          color: color,
          isKcal: isKcal,
        ),
        _CompareBar(
          type: DiaryDayType.rest,
          value: rest,
          share: max <= 0 ? 0 : rest / max,
          color: color.withValues(alpha: AppProgress.restBarOpacity),
          isKcal: isKcal,
        ),
      ],
    );
  }
}

class _CompareBar extends StatelessWidget {
  const new({
    required this.type,
    required this.value,
    required this.share,
    required this.color,
    required this.isKcal,
  });

  final DiaryDayType type;
  final double value;
  final double share;
  final Color color;
  final bool isKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(value.round());
    return Row(
      children: [
        SizedBox(
          width: AppProgress.dayTypeWidth,
          child: Text(diaryDayTypeEmoji(type), style: textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Container(
            height: AppProgress.compareBarHeight,
            color: colors.track,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: share.clamp(0, 1).toDouble(),
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          ),
        ),
        SizedBox(
          width: AppProgress.compareValueWidth,
          child: Text(
            isKcal ? l10n.progressKcal(number) : l10n.progressGrams(number),
            textAlign: TextAlign.end,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
