import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_balance_summary_view.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calories summary card.
class CaloriesSummaryCard extends ConsumerStatefulWidget {
  /// The calories summary card.
  const CaloriesSummaryCard({
    required this.consumedKcal,
    required this.goalKcal,
    required this.remainingKcal,
    required this.progress,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.consumedLabel,
    required this.goalLabel,
    required this.remainingLabel,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
    super.key,
  });

  /// The consumed kcal.
  final double consumedKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The remaining kcal.
  final double remainingKcal;

  /// The progress.
  final double progress;

  /// The total protein.
  final double totalProtein;

  /// The total carbs.
  final double totalCarbs;

  /// The total fat.
  final double totalFat;

  /// The consumed label.
  final String consumedLabel;

  /// The goal label.
  final String goalLabel;

  /// The remaining label.
  final String remainingLabel;

  /// The protein label.
  final String proteinLabel;

  /// The carbs label.
  final String carbsLabel;

  /// The fat label.
  final String fatLabel;

  @override
  ConsumerState<CaloriesSummaryCard> createState() =>
      _CaloriesSummaryCardState();
}

class _CaloriesSummaryCardState extends ConsumerState<CaloriesSummaryCard> {
  ProviderSubscription<AsyncValue<CalorieBalanceSummaryData>>?
  _balanceSummarySubscription;
  var _includeClassicActivityDelta = false;
  var _includeClassicCarryover = false;
  (DateTime, int, int, bool)? _classicAdjustmentSeed;

  @override
  void initState() {
    super.initState();
    _applyClassicAdjustmentState(ref.read(calorieBalanceSummaryProvider).value);
    _balanceSummarySubscription = ref.listenManual(
      calorieBalanceSummaryProvider,
      _handleBalanceSummaryChanged,
    );
  }

  @override
  void dispose() {
    _balanceSummarySubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;
    final gramUnit = l10n.caloriesUnitGram;
    final macroGoals = _MacroGoals.fromGoalKcal(widget.goalKcal);
    final consumedValue =
        '${numberFormat.format(widget.consumedKcal.round())} $kcalUnit';
    final viewMode = ref.watch(calorieSummaryViewModeControllerProvider);
    final balanceData = ref.watch(calorieBalanceSummaryProvider).value;
    final classicGoalKcal = _resolveClassicGoalKcal(
      goalKcal: widget.goalKcal,
      balanceData: balanceData,
      includeActivityDelta: _includeClassicActivityDelta,
      includeCarryover: _includeClassicCarryover,
    );
    final classicRemainingKcal = classicGoalKcal - widget.consumedKcal;
    final classicProgress = classicGoalKcal <= 0
        ? (widget.consumedKcal > 0 ? 1.0 : 0.0)
        : (widget.consumedKcal / classicGoalKcal).clamp(0.0, 1.0);

    return DecoratedBox(
      key: CaloriesPageKeys.summaryCard,
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colorScheme,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryModeToggle(
                  viewMode: viewMode,
                  onChanged: ref
                      .read(calorieSummaryViewModeControllerProvider.notifier)
                      .setMode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: switch (viewMode) {
                      CalorieSummaryViewMode.balance =>
                        _BalanceFlexGoalHeaderStat(
                          numberFormat: numberFormat,
                          kcalUnit: kcalUnit,
                        ),
                      CalorieSummaryViewMode.classic => _ClassicHeaderStats(
                        consumedLabel: widget.consumedLabel,
                        consumedValue: consumedValue,
                        goalLabel: widget.goalLabel,
                        goalValue:
                            '${numberFormat.format(classicGoalKcal.round())} '
                            '$kcalUnit',
                      ),
                    },
                  ),
                ),
              ],
            ),
            if (viewMode == CalorieSummaryViewMode.balance)
              _SummaryActivityDeltaNote(
                numberFormat: numberFormat,
                kcalUnit: kcalUnit,
              ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (viewMode) {
                CalorieSummaryViewMode.classic => _ClassicSummaryHero(
                  key: const ValueKey<String>('classic_summary_hero'),
                  remainingKcal: classicRemainingKcal,
                  progress: classicProgress,
                  color: classicRemainingKcal < 0
                      ? colorScheme.error
                      : colorScheme.primary,
                  label: widget.remainingLabel,
                  numberFormat: numberFormat,
                ),
                CalorieSummaryViewMode.balance => _BalanceSummaryHero(
                  key: const ValueKey<String>('balance_summary_hero'),
                  numberFormat: numberFormat,
                  kcalUnit: kcalUnit,
                ),
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _MacroProgressCard(
                    macroId: 'carbs',
                    label: widget.carbsLabel,
                    current: widget.totalCarbs,
                    target: macroGoals.carbs,
                    color: const Color(0xFF3B82F6),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MacroProgressCard(
                    macroId: 'protein',
                    label: widget.proteinLabel,
                    current: widget.totalProtein,
                    target: macroGoals.protein,
                    color: const Color(0xFFF97316),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MacroProgressCard(
                    macroId: 'fat',
                    label: widget.fatLabel,
                    current: widget.totalFat,
                    target: macroGoals.fat,
                    color: const Color(0xFFEF4444),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
              ],
            ),
            if (viewMode == CalorieSummaryViewMode.classic) ...[
              const SizedBox(height: AppSpacing.lg),
              _ClassicSummaryMetaToggles(
                data: balanceData,
                numberFormat: numberFormat,
                kcalUnit: kcalUnit,
                includeActivityDelta: _includeClassicActivityDelta,
                includeCarryover: _includeClassicCarryover,
                onToggleActivityDelta: (value) {
                  setState(() {
                    _includeClassicActivityDelta = value;
                  });
                },
                onToggleCarryover: (value) {
                  setState(() {
                    _includeClassicCarryover = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleBalanceSummaryChanged(
    AsyncValue<CalorieBalanceSummaryData>? previous,
    AsyncValue<CalorieBalanceSummaryData> next,
  ) {
    if (!_applyClassicAdjustmentState(next.value) || !mounted) {
      return;
    }
    setState(() {});
  }

  bool _applyClassicAdjustmentState(CalorieBalanceSummaryData? data) {
    final nextSeed = data == null
        ? null
        : (
            data.selectedDay,
            data.activityDeltaKcal.round(),
            data.carryoverKcal.round(),
            data.usedLearnedTdee,
          );
    if (_classicAdjustmentSeed == nextSeed) {
      return false;
    }

    _classicAdjustmentSeed = nextSeed;
    _includeClassicActivityDelta = data?.usedLearnedTdee == true;
    _includeClassicCarryover = false;
    return true;
  }
}

class _SummaryModeToggle extends StatelessWidget {
  const _SummaryModeToggle({required this.viewMode, required this.onChanged});

  final CalorieSummaryViewMode viewMode;
  final Future<void> Function(CalorieSummaryViewMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        key: CaloriesPageKeys.summaryModeToggle,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppInventoryEditorialSurfaces.ghostBorder(colors),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryModeChip(
                label: l10n.caloriesSummaryViewBalance,
                isSelected: viewMode == CalorieSummaryViewMode.balance,
                onTap: () => onChanged(CalorieSummaryViewMode.balance),
                textKey: CaloriesPageKeys.summaryModeOption(
                  CalorieSummaryViewMode.balance.name,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              _SummaryModeChip(
                label: l10n.caloriesSummaryViewClassic,
                isSelected: viewMode == CalorieSummaryViewMode.classic,
                onTap: () => onChanged(CalorieSummaryViewMode.classic),
                textKey: CaloriesPageKeys.summaryModeOption(
                  CalorieSummaryViewMode.classic.name,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryModeChip extends StatelessWidget {
  const _SummaryModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textKey,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Key textKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            key: textKey,
            style: textTheme.labelMedium?.copyWith(
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicSummaryHero extends StatelessWidget {
  const _ClassicSummaryHero({
    required this.remainingKcal,
    required this.progress,
    required this.color,
    required this.label,
    required this.numberFormat,
    super.key,
  });

  final double remainingKcal;
  final double progress;
  final Color color;
  final String label;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayedValue = numberFormat.format(remainingKcal.round());

    return Center(
      child: SizedBox.square(
        dimension: 196,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 168,
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  color: color,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayedValue,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSummaryHero extends StatelessWidget {
  const _BalanceSummaryHero({
    required this.numberFormat,
    required this.kcalUnit,
    super.key,
  });

  final NumberFormat numberFormat;
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    return _BalanceSummaryHeroContent(
      numberFormat: numberFormat,
      kcalUnit: kcalUnit,
    );
  }
}

class _BalanceSummaryHeroContent extends ConsumerWidget {
  const _BalanceSummaryHeroContent({
    required this.numberFormat,
    required this.kcalUnit,
  });

  final NumberFormat numberFormat;
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

class _BalanceFlexGoalHeaderStat extends ConsumerWidget {
  const _BalanceFlexGoalHeaderStat({
    required this.numberFormat,
    required this.kcalUnit,
  });

  final NumberFormat numberFormat;
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

class _SummaryActivityDeltaNote extends ConsumerWidget {
  const _SummaryActivityDeltaNote({
    required this.numberFormat,
    required this.kcalUnit,
  });

  final NumberFormat numberFormat;
  final String kcalUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceState = ref.watch(calorieBalanceSummaryProvider);
    final data = balanceState.value;
    if (data == null || !_hasSummaryMeta(data)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerRight,
        child: _SummaryMetaContent(
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

class _ClassicSummaryMetaToggles extends StatelessWidget {
  const _ClassicSummaryMetaToggles({
    required this.data,
    required this.numberFormat,
    required this.kcalUnit,
    required this.includeActivityDelta,
    required this.includeCarryover,
    required this.onToggleActivityDelta,
    required this.onToggleCarryover,
  });

  final CalorieBalanceSummaryData? data;
  final NumberFormat numberFormat;
  final String kcalUnit;
  final bool includeActivityDelta;
  final bool includeCarryover;
  final ValueChanged<bool> onToggleActivityDelta;
  final ValueChanged<bool> onToggleCarryover;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedData = data;
    final l10n = AppLocalizations.of(context)!;
    if (resolvedData == null || !_hasSummaryMeta(resolvedData)) {
      return const SizedBox.shrink();
    }
    final activityDeltaValue = numberFormat.format(
      resolvedData.activityDeltaKcal.round(),
    );
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
            if (resolvedData.usedLearnedTdee)
              _SummaryMetaToggleRow(
                value: includeActivityDelta,
                onChanged: onToggleActivityDelta,
                label:
                    '${l10n.caloriesWeeklyCheckInDialogTodayDeltaLabel}: '
                    '${resolvedData.activityDeltaKcal.round() > 0 ? '+' : ''}'
                    '$activityDeltaValue $kcalUnit',
                toggleKey: CaloriesPageKeys.summaryActivityDeltaToggle,
                textKey: CaloriesPageKeys.summaryActivityDeltaNote,
              ),
            if (resolvedData.usedLearnedTdee &&
                resolvedData.carryoverKcal.round() != 0)
              const SizedBox(height: AppSpacing.xs),
            if (resolvedData.carryoverKcal.round() != 0)
              _SummaryMetaToggleRow(
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

class _SummaryMetaToggleRow extends StatelessWidget {
  const _SummaryMetaToggleRow({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.toggleKey,
    required this.textKey,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Key toggleKey;
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
          children: [
            Checkbox(
              key: toggleKey,
              value: value,
              onChanged: (nextValue) => onChanged(nextValue ?? false),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                key: textKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetaContent extends StatelessWidget {
  const _SummaryMetaContent({
    required this.data,
    required this.numberFormat,
    required this.kcalUnit,
    required this.alignment,
    required this.textAlign,
  });

  final CalorieBalanceSummaryData data;
  final NumberFormat numberFormat;
  final String kcalUnit;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final roundedDelta = data.activityDeltaKcal.round();
    final activitySign = roundedDelta > 0 ? '+' : '';
    final roundedCarryover = data.carryoverKcal.round();
    final carryoverSign = roundedCarryover > 0 ? '+' : '';
    final showActivityDelta = data.usedLearnedTdee;
    final showCarryover = roundedCarryover != 0;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (showActivityDelta)
          Text(
            '${l10n.caloriesWeeklyCheckInDialogTodayDeltaLabel}: '
            '$activitySign${numberFormat.format(roundedDelta)} $kcalUnit',
            key: CaloriesPageKeys.summaryActivityDeltaNote,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
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

bool _hasSummaryMeta(CalorieBalanceSummaryData data) {
  return data.usedLearnedTdee || data.carryoverKcal.round() != 0;
}

double _resolveClassicGoalKcal({
  required double goalKcal,
  required CalorieBalanceSummaryData? balanceData,
  required bool includeActivityDelta,
  required bool includeCarryover,
}) {
  if (balanceData == null) {
    return goalKcal;
  }

  var resolvedGoalKcal = goalKcal;
  if (!includeActivityDelta && balanceData.usedLearnedTdee) {
    resolvedGoalKcal -= balanceData.activityDeltaKcal;
  }
  if (includeCarryover) {
    resolvedGoalKcal += balanceData.carryoverKcal;
  }
  return resolvedGoalKcal;
}

class _ClassicHeaderStats extends StatelessWidget {
  const _ClassicHeaderStats({
    required this.consumedLabel,
    required this.consumedValue,
    required this.goalLabel,
    required this.goalValue,
  });

  final String consumedLabel;
  final String consumedValue;
  final String goalLabel;
  final String goalValue;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderStat(label: consumedLabel, value: consumedValue),
          const SizedBox(width: AppSpacing.xl),
          _HeaderStat(label: goalLabel, value: goalValue),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
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

class _MacroProgressCard extends StatelessWidget {
  const _MacroProgressCard({
    required this.macroId,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unitLabel,
    required this.numberFormat,
  });

  final String macroId;
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unitLabel;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValueColor = current > target ? color : colorScheme.onSurface;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final currentText = numberFormat.format(current.round());
    final targetText = numberFormat.format(target.round());
    final backgroundColor = Color.alphaBlend(
      color.withValues(alpha: 0.06),
      colorScheme.surfaceContainerLowest,
    );
    final trackColor = Color.alphaBlend(
      color.withValues(alpha: 0.03),
      colorScheme.surfaceContainerHigh,
    );

    return DecoratedBox(
      key: CaloriesPageKeys.summaryMacroCard(macroId),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SizedBox(
          height: 82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final labelStyle = Theme.of(context).textTheme.labelSmall
                      ?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.95,
                      );
                  final displayLabel = _resolveMacroLabel(
                    context: context,
                    label: label.toUpperCase(),
                    style: labelStyle,
                    maxWidth: constraints.maxWidth,
                  );

                  return Text(
                    displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: labelStyle,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              RichText(
                key: CaloriesPageKeys.summaryMacroValue(macroId),
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currentText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: currentValueColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                    ),
                    TextSpan(
                      text: ' / $targetText$unitLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: trackColor),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          key: CaloriesPageKeys.summaryMacroBar(macroId),
                          widthFactor: progress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _resolveMacroLabel({
  required BuildContext context,
  required String label,
  required TextStyle? style,
  required double maxWidth,
}) {
  return resolveMacroLabelForWidth(
    label: label,
    style: style,
    maxWidth: maxWidth,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );
}

/// Resolve macro label for width.
@visibleForTesting
String resolveMacroLabelForWidth({
  required String label,
  required TextStyle? style,
  required double maxWidth,
  required ui.TextDirection textDirection,
  required TextScaler textScaler,
}) {
  if (label.isEmpty || style == null || maxWidth <= 0) {
    return label;
  }

  final textPainter = TextPainter(
    maxLines: 1,
    textDirection: textDirection,
    textScaler: textScaler,
  );

  if (doesCaloriesSummaryTextFitWidth(
    textPainter: textPainter,
    text: label,
    style: style,
    maxWidth: maxWidth,
  )) {
    return label;
  }

  var bestLabel = '${label.substring(0, 1)}.';
  var low = 1;
  var high = label.length - 1;

  while (low <= high) {
    final middle = low + ((high - low) ~/ 2);
    final shortenedLabel = '${label.substring(0, middle).trimRight()}.';
    if (doesCaloriesSummaryTextFitWidth(
      textPainter: textPainter,
      text: shortenedLabel,
      style: style,
      maxWidth: maxWidth,
    )) {
      bestLabel = shortenedLabel;
      low = middle + 1;
      continue;
    }
    high = middle - 1;
  }

  return bestLabel;
}

/// Does calories summary text fit width.
@visibleForTesting
bool doesCaloriesSummaryTextFitWidth({
  required String text,
  required TextStyle style,
  required double maxWidth,
  TextPainter? textPainter,
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final resolvedTextPainter =
      textPainter ??
            TextPainter(
              maxLines: 1,
              textDirection: textDirection,
              textScaler: textScaler,
            )
        ..text = TextSpan(text: text, style: style)
        ..layout(maxWidth: maxWidth);

  return !resolvedTextPainter.didExceedMaxLines;
}

class _MacroGoals {
  const _MacroGoals({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  factory _MacroGoals.fromGoalKcal(double goalKcal) {
    return _MacroGoals(
      carbs: goalKcal * 0.45 / 4,
      protein: goalKcal * 0.25 / 4,
      fat: goalKcal * 0.30 / 9,
    );
  }

  final double carbs;
  final double protein;
  final double fat;
}
