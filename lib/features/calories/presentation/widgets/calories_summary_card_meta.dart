import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_balance_summary_view.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hosts the balance-mode hero content.
class BalanceSummaryHero extends StatelessWidget {
  /// Creates the balance summary hero host.
  const BalanceSummaryHero({
    required this.numberFormat,
    required this.kcalUnit,
    super.key,
  });

  /// Number formatter used for calorie values.
  final NumberFormat numberFormat;

  /// Localized calorie unit label.
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    return BalanceSummaryHeroContent(
      numberFormat: numberFormat,
      kcalUnit: kcalUnit,
    );
  }
}

/// Resolves and renders the balance-mode hero state.
class BalanceSummaryHeroContent extends ConsumerWidget {
  /// Creates the balance summary hero content widget.
  const BalanceSummaryHeroContent({
    required this.numberFormat,
    required this.kcalUnit,
    super.key,
  });

  /// Number formatter used for calorie values.
  final NumberFormat numberFormat;

  /// Localized calorie unit label.
  final String kcalUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceState = ref.watch(calorieBalanceSummaryProvider);

    return balanceState.when(
      data: (data) => CaloriesBalanceSummaryView(
        data: data,
        numberFormat: numberFormat,
        kcalUnit: kcalUnit,
      ),
      loading: () => const SizedBox(
        height: 172,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => SizedBox(
        height: 172,
        child: Center(
          child: Text(
            l10n.caloriesBalanceUnavailable,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Shows the balance-mode flex-goal stat in the card header.
class BalanceFlexGoalHeaderStat extends ConsumerWidget {
  /// Creates the balance-mode flex-goal header stat.
  const BalanceFlexGoalHeaderStat({
    required this.numberFormat,
    required this.kcalUnit,
    super.key,
  });

  /// Number formatter used for calorie values.
  final NumberFormat numberFormat;

  /// Localized calorie unit label.
  final String kcalUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final balanceState = ref.watch(calorieBalanceSummaryProvider);
    final flexGoalText = switch (balanceState.value) {
      final data? =>
        '${numberFormat.format(data.flexibleGoalKcal.round())} $kcalUnit',
      null => '...',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          l10n.caloriesBalanceFlexGoalLabel.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          flexGoalText,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Shows the right-aligned activity-delta note in balance mode.
class SummaryActivityDeltaNote extends ConsumerWidget {
  /// Creates the balance-mode activity-delta note.
  const SummaryActivityDeltaNote({
    required this.numberFormat,
    required this.kcalUnit,
    super.key,
  });

  /// Number formatter used for calorie values.
  final NumberFormat numberFormat;

  /// Localized calorie unit label.
  final String kcalUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceState = ref.watch(calorieBalanceSummaryProvider);
    final data = balanceState.value;
    if (data == null || !hasSummaryMeta(data)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerRight,
        child: SummaryMetaContent(
          data: data,
          numberFormat: numberFormat,
          kcalUnit: kcalUnit,
          alignment: CrossAxisAlignment.end,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

/// Shows the classic-mode adjustment toggles below the hero.
class ClassicSummaryMetaToggles extends StatelessWidget {
  /// Creates the classic-mode adjustment toggle section.
  const ClassicSummaryMetaToggles({
    required this.data,
    required this.numberFormat,
    required this.kcalUnit,
    required this.includeActivityDelta,
    required this.includeCarryover,
    required this.onToggleActivityDelta,
    required this.onToggleCarryover,
    super.key,
  });

  /// Resolved balance summary data for the selected day.
  final CalorieBalanceSummaryData? data;

  /// Number formatter used for calorie values.
  final NumberFormat numberFormat;

  /// Localized calorie unit label.
  final String kcalUnit;

  /// Whether activity delta is currently included in the classic target.
  final bool includeActivityDelta;

  /// Whether carryover is currently included in the classic target.
  final bool includeCarryover;

  /// Callback invoked when the activity-delta toggle changes.
  final ValueChanged<bool> onToggleActivityDelta;

  /// Callback invoked when the carryover toggle changes.
  final ValueChanged<bool> onToggleCarryover;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedData = data;
    final l10n = AppLocalizations.of(context)!;
    if (resolvedData == null || !hasClassicSummaryMetaToggles(resolvedData)) {
      return const SizedBox.shrink();
    }
    final roundedActivityDelta = resolvedData.activityDeltaKcal.round();
    final activityDeltaValue = numberFormat.format(roundedActivityDelta);
    final showActivityAdjustment = roundedActivityDelta != 0;
    final activityAdjustmentLabel = _activityMetaLabel(
      l10n: l10n,
      data: resolvedData,
    );
    final activityAdjustmentHint = resolvedData.usedLearnedTdee
        ? null
        : l10n.caloriesActivityLearningHint;
    final carryoverValue = numberFormat.format(
      resolvedData.carryoverKcal.round(),
    );

    return DecoratedBox(
      key: CaloriesPageKeys.summaryMetaSection,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showActivityAdjustment)
              SummaryMetaToggleRow(
                value: includeActivityDelta,
                onChanged: onToggleActivityDelta,
                label:
                    '$activityAdjustmentLabel: '
                    '${roundedActivityDelta > 0 ? '+' : ''}'
                    '$activityDeltaValue $kcalUnit',
                supportingText: activityAdjustmentHint,
                toggleKey: CaloriesPageKeys.summaryActivityDeltaToggle,
                textKey: CaloriesPageKeys.summaryActivityDeltaNote,
              ),
            if (showActivityAdjustment &&
                resolvedData.carryoverKcal.round() != 0)
              const SizedBox(height: AppSpacing.xs),
            if (resolvedData.carryoverKcal.round() != 0)
              SummaryMetaToggleRow(
                value: includeCarryover,
                onChanged: onToggleCarryover,
                label:
                    '${l10n.caloriesBalanceCarryoverNoteLabel}: '
                    '${resolvedData.carryoverKcal.round() > 0 ? '+' : ''}'
                    '$carryoverValue $kcalUnit',
                toggleKey: CaloriesPageKeys.summaryCarryoverToggle,
                textKey: CaloriesPageKeys.summaryCarryoverNote,
              ),
          ],
        ),
      ),
    );
  }
}

/// One tap target row with a checkbox for a classic-mode adjustment.
class SummaryMetaToggleRow extends StatelessWidget {
  /// Creates a summary meta toggle row.
  const SummaryMetaToggleRow({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.toggleKey,
    required this.textKey,
    this.supportingText,
    super.key,
  });

  /// Whether the toggle is currently selected.
  final bool value;

  /// Callback invoked when the row toggles.
  final ValueChanged<bool> onChanged;

  /// Localized label shown next to the checkbox.
  final String label;

  /// Optional supporting hint shown below the label.
  final String? supportingText;

  /// Key applied to the checkbox for widget tests.
  final Key toggleKey;

  /// Key applied to the label for widget tests.
  final Key textKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: toggleKey,
              value: value,
              onChanged: (nextValue) => onChanged(nextValue ?? false),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    key: textKey,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (supportingText != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      supportingText!,
                      key: CaloriesPageKeys.summaryActivityHint,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the activity and carryover note text block.
class SummaryMetaContent extends StatelessWidget {
  /// Creates the summary meta note content.
  const SummaryMetaContent({
    required this.data,
    required this.numberFormat,
    required this.kcalUnit,
    required this.alignment,
    required this.textAlign,
    super.key,
  });

  /// Balance summary data that drives the displayed notes.
  final CalorieBalanceSummaryData data;

  /// Number formatter used for calorie values.
  final NumberFormat numberFormat;

  /// Localized calorie unit label.
  final String kcalUnit;

  /// Horizontal alignment for the text column.
  final CrossAxisAlignment alignment;

  /// Text alignment used inside each note label.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final roundedDisplayedActivityKcal = _displayedActivityMetaKcal(
      data,
    ).round();
    final activitySign = roundedDisplayedActivityKcal > 0 ? '+' : '';
    final roundedCarryover = data.carryoverKcal.round();
    final carryoverSign = roundedCarryover > 0 ? '+' : '';
    final showActivityDelta = roundedDisplayedActivityKcal != 0;
    final activityLabel = _activityMetaLabel(l10n: l10n, data: data);
    final activityHint = data.usedLearnedTdee
        ? null
        : l10n.caloriesActivityLearningHint;
    final showCarryover = roundedCarryover != 0;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (showActivityDelta)
          Text(
            '$activityLabel: '
            '$activitySign'
            '${numberFormat.format(roundedDisplayedActivityKcal)} $kcalUnit',
            key: CaloriesPageKeys.summaryActivityDeltaNote,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (showActivityDelta && activityHint != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              activityHint,
              key: CaloriesPageKeys.summaryActivityHint,
              textAlign: textAlign,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        if (showActivityDelta && showCarryover)
          const SizedBox(height: AppSpacing.xxs),
        if (showCarryover)
          Text(
            '${l10n.caloriesBalanceCarryoverNoteLabel}: '
            '$carryoverSign${numberFormat.format(roundedCarryover)} '
            '$kcalUnit',
            key: CaloriesPageKeys.summaryCarryoverNote,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Returns whether any summary meta information should be shown.
bool hasSummaryMeta(CalorieBalanceSummaryData data) {
  return _displayedActivityMetaKcal(data).round() != 0 ||
      data.carryoverKcal.round() != 0;
}

/// Returns whether any classic-mode adjustment toggles should be shown.
bool hasClassicSummaryMetaToggles(CalorieBalanceSummaryData data) {
  return data.activityDeltaKcal.round() != 0 || data.carryoverKcal.round() != 0;
}

/// Resolves the classic-mode goal after optional daily adjustments.
double resolveClassicGoalKcal({
  required double goalKcal,
  required CalorieBalanceSummaryData? balanceData,
  required bool includeActivityDelta,
  required bool includeCarryover,
}) {
  if (balanceData == null) {
    return goalKcal;
  }

  var resolvedGoalKcal = goalKcal;
  if (!includeActivityDelta && balanceData.activityDeltaKcal.round() != 0) {
    resolvedGoalKcal -= balanceData.activityDeltaKcal;
  }
  if (includeCarryover) {
    resolvedGoalKcal += balanceData.carryoverKcal;
  }
  return resolvedGoalKcal;
}

double _displayedActivityMetaKcal(CalorieBalanceSummaryData data) {
  return data.usedLearnedTdee
      ? data.activityComparisonKcal
      : data.activityDeltaKcal;
}

String _activityMetaLabel({
  required AppLocalizations l10n,
  required CalorieBalanceSummaryData data,
}) {
  if (!data.usedLearnedTdee) {
    return l10n.caloriesActivityWorkoutBonusLabel;
  }
  return data.isCurrentDay
      ? l10n.caloriesActivityTodayVsUsualLabel
      : l10n.caloriesActivityVsUsualLabel;
}

/// Shows the classic-mode consumed and goal stats in the header.
class ClassicHeaderStats extends StatelessWidget {
  /// Creates the classic-mode header stats row.
  const ClassicHeaderStats({
    required this.consumedLabel,
    required this.consumedValue,
    required this.goalLabel,
    required this.goalValue,
    super.key,
  });

  /// Label shown above the consumed value.
  final String consumedLabel;

  /// Consumed value shown in the header.
  final String consumedValue;

  /// Label shown above the goal value.
  final String goalLabel;

  /// Goal value shown in the header.
  final String goalValue;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderStat(label: consumedLabel, value: consumedValue),
          const SizedBox(width: AppSpacing.xl),
          HeaderStat(label: goalLabel, value: goalValue),
        ],
      ),
    );
  }
}

/// Displays one label/value column inside the header stats row.
class HeaderStat extends StatelessWidget {
  /// Creates a header stat column.
  const HeaderStat({
    required this.label,
    required this.value,
    super.key,
  });

  /// Uppercase label shown above the stat value.
  final String label;

  /// Value shown below the stat label.
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.95,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
