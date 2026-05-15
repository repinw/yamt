import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/metric_card_shell/metric_card_shell.dart';
import 'package:yamt/core/widgets/metric_card_shell/metric_tap_shell.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_workouts_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact activity metric card for the diary page.
class DiaryActivityCard extends StatelessWidget {
  /// Creates an activity card.
  const DiaryActivityCard({
    required this.data,
    required this.isExpanded,
    required this.onToggleExpanded,
    super.key,
  });

  /// Loaded activity and weight data.
  final DiaryActivityWeightData data;

  /// Whether the details panel is expanded.
  final bool isExpanded;

  /// Toggles the activity details panel.
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = MetricAccentColors.of(context);
    return MetricTapShell(
      onTap: onToggleExpanded,
      child: MetricCardShell(
        accentColor: accentColors.activity,
        watermarkIcon: Icons.local_activity_rounded,
        titleIcon: Icons.local_activity_rounded,
        title: l10n.diaryActivityTitle,
        value: data.activityKcal == null
            ? '—'
            : numberFormat.format(data.activityKcal),
        unit: l10n.caloriesUnitKcal,
        trend: data.activityTrend,
        footer: data.activeMinutes == null
            ? l10n.diaryActivityEmpty
            : l10n.diaryActiveMinutesLabel(
                numberFormat.format(data.activeMinutes),
              ),
        periodLabel: l10n.diarySevenDaysLabel,
        trailing: AnimatedRotation(
          turns: isExpanded ? 0.25 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.chevron_right_rounded,
            color: accentColors.activity,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Expanded trainings panel for the activity card.
class DiaryActivityTrainingsPanel extends StatelessWidget {
  /// Creates the trainings panel.
  const DiaryActivityTrainingsPanel({
    required this.selectedDay,
    super.key,
  });

  /// Selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return DiaryWorkoutsCard(selectedDay: selectedDay);
  }
}
