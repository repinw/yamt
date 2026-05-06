import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/provider/diary_steps_summary_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Workout session list for the diary page.
class DiaryWorkoutsCard extends ConsumerWidget {
  /// Creates the workouts card.
  const DiaryWorkoutsCard({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final summaryState = ref.watch(diaryStepsSummaryProvider(normalizedDay));

    return summaryState.when(
      loading: () => const DiaryDetailCardShell(child: _WorkoutsSkeleton()),
      error: (_, _) => DiaryDetailCardShell(
        child: DiaryErrorRetryContent(
          message: AppLocalizations.of(context)!.diaryWorkoutsLoadFailed,
          retryLabel: AppLocalizations.of(context)!.caloriesRetryAction,
          onRetry: () => ref.invalidate(
            diaryStepsSummaryProvider(normalizedDay),
          ),
        ),
      ),
      data: (summary) {
        if (summary.accessState != HealthDataAccessState.ready) {
          return const SizedBox.shrink();
        }
        return DiaryDetailCardShell(
          child: _WorkoutsContent(workouts: summary.workouts),
        );
      },
    );
  }
}

class _WorkoutsContent extends StatelessWidget {
  const _WorkoutsContent({required this.workouts});

  final List<HealthWorkoutSession> workouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkoutsHeader(),
        const SizedBox(height: AppSpacing.lg),
        if (workouts.isEmpty)
          Text(
            l10n.diaryWorkoutsEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          for (final workout in workouts) ...[
            _WorkoutRow(workout: workout),
            if (workout != workouts.last) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 1,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
      ],
    );
  }
}

class _WorkoutsHeader extends StatelessWidget {
  const _WorkoutsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);
    return Row(
      children: [
        Icon(
          Icons.fitness_center_rounded,
          color: accentColors.activity,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            l10n.diaryWorkoutsTitle.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout});

  final HealthWorkoutSession workout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final timeFormat = DateFormat.Hm(locale);
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);
    final title = workout.activityLabel ?? l10n.diaryWorkoutFallbackTitle;
    final timeRange =
        '${timeFormat.format(workout.start)} - '
        '${timeFormat.format(workout.endExclusive)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColors.activity.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: accentColors.activity,
            size: 19,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                workout.sourceName?.trim().isNotEmpty == true
                    ? '$timeRange · ${workout.sourceName!.trim()}'
                    : timeRange,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.diaryWorkoutMinutesLabel(
                numberFormat.format(workout.durationMinutes.round()),
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (workout.totalCalories != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${numberFormat.format(workout.totalCalories)} '
                '${l10n.caloriesUnitKcal}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _WorkoutsSkeleton extends StatelessWidget {
  const _WorkoutsSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiarySkeletonBlock(width: 90, height: 14, color: color),
        const SizedBox(height: AppSpacing.lg),
        DiarySkeletonBlock(height: 34, color: color),
        const SizedBox(height: AppSpacing.md),
        DiarySkeletonBlock(height: 34, color: color),
      ],
    );
  }
}
