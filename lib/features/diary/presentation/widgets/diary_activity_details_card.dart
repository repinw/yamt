import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/provider/diary_steps_summary_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Detailed step breakdown for the diary page.
class DiaryActivityDetailsCard extends ConsumerWidget {
  /// Creates the step details card.
  const DiaryActivityDetailsCard({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final summaryState = ref.watch(diaryStepsSummaryProvider(normalizedDay));

    return summaryState.when(
      loading: () => const DiaryDetailCardShell(
        child: _ActivityDetailsSkeleton(),
      ),
      error: (_, _) => DiaryDetailCardShell(
        child: DiaryErrorRetryContent(
          message: AppLocalizations.of(context)!.diaryStepsLoadFailed,
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
          child: _ActivityDetailsContent(summary: summary),
        );
      },
    );
  }
}

class _ActivityDetailsContent extends StatelessWidget {
  const _ActivityDetailsContent({required this.summary});

  final DiaryActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActivityDetailsHeader(
          title: l10n.diaryStepDetailsTitle,
          icon: Icons.directions_walk_rounded,
          color: accentColors.stepsFor(Theme.of(context).brightness),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(
          label: l10n.diaryStepsDuringWorkoutsLabel,
          value: summary.stepsDuringWorkouts == null
              ? '-'
              : numberFormat.format(summary.stepsDuringWorkouts),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailRow(
          label: l10n.diaryStepsOutsideWorkoutsLabel,
          value: summary.stepsOutsideWorkouts == null
              ? '-'
              : numberFormat.format(summary.stepsOutsideWorkouts),
        ),
      ],
    );
  }
}

class _ActivityDetailsHeader extends StatelessWidget {
  const _ActivityDetailsHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title.toUpperCase(),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ActivityDetailsSkeleton extends StatelessWidget {
  const _ActivityDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiarySkeletonBlock(width: 120, height: 14, color: color),
        const SizedBox(height: AppSpacing.lg),
        DiarySkeletonBlock(height: 16, color: color),
        const SizedBox(height: AppSpacing.sm),
        DiarySkeletonBlock(height: 16, color: color),
        const SizedBox(height: AppSpacing.sm),
        DiarySkeletonBlock(height: 16, color: color),
      ],
    );
  }
}
