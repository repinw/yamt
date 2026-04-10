import 'dart:ui' as ui;
import 'dart:math' as math;

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

class CaloriesSummaryCard extends ConsumerWidget {
  const CaloriesSummaryCard({
    super.key,
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
  });

  final double consumedKcal;
  final double goalKcal;
  final double remainingKcal;
  final double progress;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String consumedLabel;
  final String goalLabel;
  final String remainingLabel;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;
    final gramUnit = l10n.caloriesUnitGram;
    final macroGoals = _MacroGoals.fromGoalKcal(goalKcal);
    final viewMode = ref.watch(calorieSummaryViewModeControllerProvider);

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
                        consumedLabel: consumedLabel,
                        consumedValue:
                            '${numberFormat.format(consumedKcal.round())} '
                            '$kcalUnit',
                        goalLabel: goalLabel,
                        goalValue:
                            '${numberFormat.format(goalKcal.round())} '
                            '$kcalUnit',
                      ),
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (viewMode) {
                CalorieSummaryViewMode.classic => _ClassicSummaryHero(
                  key: const ValueKey<String>('classic_summary_hero'),
                  remainingKcal: remainingKcal,
                  progress: progress,
                  color: remainingKcal < 0
                      ? colorScheme.error
                      : AppInventoryEditorial.primary,
                  label: remainingLabel,
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
                    label: carbsLabel,
                    current: totalCarbs,
                    target: macroGoals.carbs,
                    color: const Color(0xFF3B82F6),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MacroProgressCard(
                    label: proteinLabel,
                    current: totalProtein,
                    target: macroGoals.protein,
                    color: const Color(0xFFF97316),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MacroProgressCard(
                    label: fatLabel,
                    current: totalFat,
                    target: macroGoals.fat,
                    color: const Color(0xFFEF4444),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
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
    super.key,
    required this.remainingKcal,
    required this.progress,
    required this.color,
    required this.label,
    required this.numberFormat,
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
    super.key,
    required this.numberFormat,
    required this.kcalUnit,
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
            letterSpacing: 1.0,
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
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unitLabel,
    required this.numberFormat,
  });

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
    final progress = target <= 0
        ? 0.0
        : (current / target).clamp(0.0, 1.0).toDouble();
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

@visibleForTesting
bool doesCaloriesSummaryTextFitWidth({
  TextPainter? textPainter,
  required String text,
  required TextStyle style,
  required double maxWidth,
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final resolvedTextPainter =
      textPainter ??
      TextPainter(
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      );
  resolvedTextPainter.text = TextSpan(text: text, style: style);
  resolvedTextPainter.layout(maxWidth: maxWidth);

  return !resolvedTextPainter.didExceedMaxLines;
}

class _MacroGoals {
  const _MacroGoals({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double carbs;
  final double protein;
  final double fat;

  factory _MacroGoals.fromGoalKcal(double goalKcal) {
    return _MacroGoals(
      carbs: goalKcal * 0.45 / 4,
      protein: goalKcal * 0.25 / 4,
      fat: goalKcal * 0.30 / 9,
    );
  }
}
