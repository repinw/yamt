import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_macros.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Data for the diary nutrition bars.
class DiaryNutritionBarsData {
  /// Creates diary nutrition bars data.
  const DiaryNutritionBarsData({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.goals,
  });

  /// Consumed carbs in grams.
  final double carbs;

  /// Consumed protein in grams.
  final double protein;

  /// Consumed fat in grams.
  final double fat;

  /// Target macro grams.
  final CaloriesSummaryMacroGoals goals;
}

/// Provides real macro totals and targets for one diary day.
final FutureProviderFamily<DiaryNutritionBarsData, DateTime>
diaryNutritionBarsDataProvider =
    FutureProvider.family<DiaryNutritionBarsData, DateTime>((ref, day) async {
      ref.watch(calorieOverviewRevisionProvider);
      final normalizedDay = normalizeDiaryDay(day);
      final repository = ref.watch(calorieLogRepositoryProvider);
      final resolvedGoal = await ref.watch(
        resolvedCalorieGoalForDayProvider(normalizedDay).future,
      );
      final entries = await repository.readEntriesForDay(normalizedDay);

      var carbs = 0.0;
      var protein = 0.0;
      var fat = 0.0;
      for (final entry in entries) {
        carbs += entry.totalCarbs;
        protein += entry.totalProtein;
        fat += entry.totalFat;
      }

      return DiaryNutritionBarsData(
        carbs: carbs,
        protein: protein,
        fat: fat,
        goals: CaloriesSummaryMacroGoals.fromGoalKcal(
          resolvedGoal.goalKcal,
        ),
      );
    });

/// Macro nutrition bars for the diary page.
class DiaryNutritionBars extends ConsumerStatefulWidget {
  /// Creates diary nutrition bars.
  const DiaryNutritionBars({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryNutritionBars> createState() => _DiaryNutritionBarsState();
}

class _DiaryNutritionBarsState extends ConsumerState<DiaryNutritionBars>
    with AutomaticKeepAliveClientMixin<DiaryNutritionBars> {
  DiaryNutritionBarsData? _lastData;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final dataState = ref.watch(
      diaryNutritionBarsDataProvider(widget.selectedDay),
    );
    final loadedData = dataState.asData?.value;
    if (loadedData != null) {
      _lastData = loadedData;
    }
    final data = loadedData ?? _lastData;

    return DiaryDetailCardShell(
      child: IconTheme.merge(
        data: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        child: data == null
            ? const _NutritionBarsSkeleton()
            : _NutritionBarsContent(data: data),
      ),
    );
  }
}

class _NutritionBarsContent extends StatelessWidget {
  const _NutritionBarsContent({required this.data});

  final DiaryNutritionBarsData data;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);

    return Row(
      children: [
        Expanded(
          child: _NutritionMacroColumn(
            label: l10n.caloriesCarbsLabel,
            current: data.carbs,
            target: data.goals.carbs,
            color: accentColors.carbs,
            numberFormat: numberFormat,
            unit: l10n.caloriesUnitGram,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: _NutritionMacroColumn(
            label: l10n.caloriesProteinLabel,
            current: data.protein,
            target: data.goals.protein,
            color: accentColors.protein,
            numberFormat: numberFormat,
            unit: l10n.caloriesUnitGram,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: _NutritionMacroColumn(
            label: l10n.caloriesFatLabel,
            current: data.fat,
            target: data.goals.fat,
            color: accentColors.fat,
            numberFormat: numberFormat,
            unit: l10n.caloriesUnitGram,
          ),
        ),
      ],
    );
  }
}

class _NutritionMacroColumn extends StatelessWidget {
  const _NutritionMacroColumn({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.numberFormat,
    required this.unit,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final NumberFormat numberFormat;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, child) {
              return FractionallySizedBox(widthFactor: value, child: child);
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: numberFormat.format(current.round()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: ' / ${numberFormat.format(target.round())}$unit',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionBarsSkeleton extends StatelessWidget {
  const _NutritionBarsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var index = 0; index < 3; index += 1) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiarySkeletonBlock(
                  width: 74,
                  height: 12,
                  color: colors.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.xs),
                DiarySkeletonBlock(
                  height: 8,
                  color: colors.surfaceContainerHighest,
                ),
                const SizedBox(height: AppSpacing.xs),
                DiarySkeletonBlock(
                  width: 58,
                  height: 14,
                  color: colors.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
