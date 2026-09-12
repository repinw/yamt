import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/presentation/widgets/goal_archive/goal_archive_detail_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Selectable summary of one current or archived goal cycle.
class GoalArchiveCard extends StatelessWidget {
  /// Creates a goal archive card.
  const GoalArchiveCard({
    required this.cycle,
    required this.selected,
    required this.onOpen,
    required this.onSelected,
    super.key,
  });

  /// Goal cycle summarized by this card.
  final TdeeAnalyticsGoalCycle cycle;

  /// Whether this cycle participates in a multi-cycle selection.
  final bool selected;

  /// Opens analytics for this cycle.
  final VoidCallback onOpen;

  /// Updates this cycle's selection state.
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: AppInkWell(
        onTap: onOpen,
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalArchiveHeader(
                cycle: cycle,
                selected: selected,
                onSelected: onSelected,
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._details(l10n, dateFormat),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _details(AppLocalizations l10n, DateFormat dateFormat) {
    final endDate = cycle.endDate;
    final estimatedEnd = cycle.estimatedEndDate;
    return [
      GoalArchiveDetailRow(
        label: l10n.goalArchiveSpeedLabel,
        value: cycle.goalMode == CalorieGoalMode.maintain
            ? '—'
            : '${cycle.goalSpeedKgPerWeek?.toStringAsFixed(2) ?? '—'} kg/Woche',
      ),
      GoalArchiveDetailRow(
        label: l10n.goalArchiveStartLabel,
        value: dateFormat.format(cycle.startDate),
      ),
      GoalArchiveDetailRow(
        label: l10n.goalArchiveStartWeightLabel,
        value: _formatWeight(cycle.startWeightKg),
      ),
      GoalArchiveDetailRow(
        label: l10n.goalArchiveEndWeightLabel,
        value: _formatWeight(cycle.endWeightKg),
      ),
      GoalArchiveDetailRow(
        label: endDate == null
            ? l10n.goalArchiveEstimatedEndLabel
            : l10n.goalArchiveEndLabel,
        value: endDate != null
            ? dateFormat.format(endDate)
            : estimatedEnd != null
            ? dateFormat.format(estimatedEnd)
            : l10n.goalArchiveUnlimited,
      ),
      if (cycle.reachedDate != null)
        GoalArchiveDetailRow(
          label: l10n.goalArchiveReachedLabel,
          value: dateFormat.format(cycle.reachedDate!),
        ),
    ];
  }

  String _formatWeight(double? value) {
    return value == null ? '—' : '${value.toStringAsFixed(1)} kg';
  }
}

class _GoalArchiveHeader extends StatelessWidget {
  const _GoalArchiveHeader({
    required this.cycle,
    required this.selected,
    required this.onSelected,
  });

  final TdeeAnalyticsGoalCycle cycle;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          cycle.isActive ? Icons.track_changes_rounded : Icons.archive_outlined,
          color: cycle.isActive ? colors.primary : colors.outline,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            _goalLabel(l10n),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Chip(
          label: Text(
            cycle.isActive ? l10n.goalArchiveActive : l10n.goalArchiveCompleted,
          ),
        ),
        Checkbox(
          value: selected,
          onChanged: (value) => onSelected(value ?? false),
        ),
      ],
    );
  }

  String _goalLabel(AppLocalizations l10n) {
    return switch (cycle.goalMode) {
      CalorieGoalMode.lose => l10n.caloriesCalculatorGoalModeLose,
      CalorieGoalMode.maintain => l10n.caloriesCalculatorGoalModeMaintain,
      CalorieGoalMode.gain => l10n.caloriesCalculatorGoalModeGain,
      null => l10n.goalArchiveGoalLabel,
    };
  }
}
