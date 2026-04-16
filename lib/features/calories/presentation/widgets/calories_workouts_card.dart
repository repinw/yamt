import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'diary_health_card_parts.dart';
import 'package:yamt/features/calories/provider/'
    'diary_activity_summary_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calories workouts card.
class CaloriesWorkoutsCard extends ConsumerWidget {
  /// The calories workouts card.
  const CaloriesWorkoutsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(diaryActivitySummaryProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return summaryAsync.when(
      loading: () => DiaryHealthCardFrame(
        title: l10n.caloriesWorkoutsTitle,
        subtitle: l10n.caloriesWorkoutsSubtitle,
        child: const LinearProgressIndicator(),
      ),
      error: (_, _) => DiaryHealthCardFrame(
        title: l10n.caloriesWorkoutsTitle,
        subtitle: l10n.caloriesWorkoutsSubtitle,
        child: Text(l10n.caloriesLoadFailed),
      ),
      data: (summary) {
        if (summary.accessState != HealthDataAccessState.ready) {
          return DiaryHealthCardFrame(
            title: l10n.caloriesWorkoutsTitle,
            subtitle: l10n.caloriesWorkoutsSubtitle,
            child: DiaryHealthConnectionPrompt(
              accessState: summary.accessState,
              androidPermissionBody: l10n.settingsHealthConnectSubtitle,
              iosPermissionBody: l10n.settingsAppleHealthConnectSubtitle,
              historyBody: l10n.settingsHealthHistorySubtitle,
              installBody: l10n.settingsHealthInstallSubtitle,
              unsupportedBody: l10n.healthUnsupportedHint,
            ),
          );
        }

        return DiaryHealthCardFrame(
          title: l10n.caloriesWorkoutsTitle,
          subtitle: l10n.caloriesWorkoutsSubtitle,
          child: _WorkoutEntriesList(
            workouts: summary.workouts,
            locale: locale,
            emptyLabel: l10n.caloriesWorkoutsEmpty,
            fallbackTitle: l10n.caloriesWorkoutsFallbackTitle,
            sourceLabel: l10n.caloriesWorkoutsSourceLabel,
            minuteUnit: l10n.caloriesWorkoutsMinuteUnit,
            calorieUnit: l10n.caloriesUnitKcal,
          ),
        );
      },
    );
  }
}

class _WorkoutEntriesList extends StatelessWidget {
  const _WorkoutEntriesList({
    required this.workouts,
    required this.locale,
    required this.emptyLabel,
    required this.fallbackTitle,
    required this.sourceLabel,
    required this.minuteUnit,
    required this.calorieUnit,
  });

  final List<HealthWorkoutSession> workouts;
  final String locale;
  final String emptyLabel;
  final String fallbackTitle;
  final String sourceLabel;
  final String minuteUnit;
  final String calorieUnit;

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Text(emptyLabel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final workout in workouts) ...[
          _WorkoutEntryRow(
            workout: workout,
            locale: locale,
            fallbackTitle: fallbackTitle,
            sourceLabel: sourceLabel,
            minuteUnit: minuteUnit,
            calorieUnit: calorieUnit,
          ),
          if (workout != workouts.last) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _WorkoutEntryRow extends StatelessWidget {
  const _WorkoutEntryRow({
    required this.workout,
    required this.locale,
    required this.fallbackTitle,
    required this.sourceLabel,
    required this.minuteUnit,
    required this.calorieUnit,
  });

  final HealthWorkoutSession workout;
  final String locale;
  final String fallbackTitle;
  final String sourceLabel;
  final String minuteUnit;
  final String calorieUnit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(locale);
    final title = workout.activityLabel ?? fallbackTitle;
    final emoji = _workoutEmoji(title);
    final timeFormat = DateFormat.Hm(locale);
    final timeRange =
        '${timeFormat.format(workout.start)} - '
        '${timeFormat.format(workout.endExclusive)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Align(
            alignment: Alignment.topLeft,
            child: emoji == null
                ? const SizedBox.shrink()
                : Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                timeRange,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (workout.sourceName != null &&
                  workout.sourceName!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$sourceLabel: ${workout.sourceName!.trim()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${numberFormat.format(workout.durationMinutes.round())} '
              '$minuteUnit',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (workout.totalCalories != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${numberFormat.format(workout.totalCalories)} $calorieUnit',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String? _workoutEmoji(String label) {
  final normalizedLabel = label.toLowerCase();
  if (normalizedLabel.contains('walk')) {
    return '🚶';
  }
  if (normalizedLabel.contains('weight') ||
      normalizedLabel.contains('strength')) {
    return '🏋️';
  }
  return null;
}
