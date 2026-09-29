import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/progress/application/progress_goal_provider.dart';
import 'package:yamt/features/progress/domain/progress_goal.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The current goal: where the user wants to go, how far the weight got,
/// the daily calories and macros, and the way to the goal archive.
class ProgressGoalCard extends ConsumerWidget {
  /// Creates the goal card.
  const new({super.key});

  /// Stable key of the card.
  static const cardKey = ValueKey<String>('progress-goal-card');

  /// Stable key of the goal archive button.
  static const archiveButtonKey = ValueKey<String>(
    'progress-goal-archive-button',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final label = FoodLabelColors.of(context);
    final goal = ref.watch(progressGoalProvider);
    return Container(
      key: cardKey,
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: label.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          goal.when(
            data: (goal) => _GoalContent(goal: goal),
            loading: () => const ProgressSectionLoading(),
            error: (_, _) => const ProgressSectionError(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: archiveButtonKey,
              onPressed: () =>
                  unawaited(context.push(AppRoutes.homeSettingsGoalArchive)),
              style: TextButton.styleFrom(foregroundColor: label.ink),
              icon: const Icon(Icons.archive_outlined),
              label: Text(l10n.settingsGoalArchiveTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalContent extends StatelessWidget {
  const new({required this.goal});

  final ProgressGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = FoodLabelColors.of(context);
    final decimal = _GoalFormats.of(context).decimal;
    final profile = goal.profile;
    if (profile == null) {
      return Text(l10n.progressGoalNone, style: theme.textTheme.bodyMedium);
    }
    final target = profile.targetWeightKg;
    final share = goal.share;
    final kgToTarget = goal.kgToTarget;
    final kgPastStart = goal.kgPastStart;
    final muted = theme.textTheme.bodySmall?.copyWith(color: label.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Text(
          switch ((profile.goalMode, target)) {
            (CalorieGoalMode.lose, final kg?) => l10n.progressGoalLose(
              decimal.format(kg),
            ),
            (CalorieGoalMode.gain, final kg?) => l10n.progressGoalGain(
              decimal.format(kg),
            ),
            _ => l10n.progressGoalMaintain,
          },
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (share != null) _GoalShareBar(share: share),
        if (target != null)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.md,
            children: [
              Text(
                l10n.progressGoalStart(decimal.format(profile.weightKg)),
                style: muted,
              ),
              if (kgToTarget != null)
                Text(
                  l10n.progressGoalRemaining(
                    decimal.format(kgToTarget),
                    decimal.format(profile.goalSpeedKgPerWeek),
                  ),
                  style: muted,
                ),
            ],
          ),
        if (kgPastStart != null)
          Text(
            kgPastStart > 0
                ? l10n.progressGoalAboveStart(decimal.format(kgPastStart))
                : l10n.progressGoalBelowStart(decimal.format(-kgPastStart)),
            style: muted?.copyWith(color: label.low),
          ),
        Divider(height: AppSizes.hairline, color: label.rule),
        _GoalTargets(goal: goal),
      ],
    );
  }
}

/// Number formats of the goal card for the current locale.
class _GoalFormats {
  factory of(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return _GoalFormats._(
      decimal: NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = 1
        ..maximumFractionDigits = 1,
      whole: NumberFormat.decimalPattern(locale)..maximumFractionDigits = 0,
    );
  }

  const new _({required this.decimal, required this.whole});

  /// A weight with one decimal, such as "82,6".
  final NumberFormat decimal;

  /// A value without decimals, such as "2.150".
  final NumberFormat whole;
}

/// Four equal segments that fill in order as the weight nears the target.
class _GoalShareBar extends StatelessWidget {
  const new({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final label = FoodLabelColors.of(context);
    const segments = AppProgress.dayBarSegments;
    return Row(
      spacing: AppSpacing.xxs,
      children: [
        for (var index = 0; index < segments; index++)
          Expanded(
            child: Container(
              height: AppProgress.legendSwatch,
              color: label.rule,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (share * segments - index).clamp(0, 1).toDouble(),
                child: ColoredBox(color: label.ink),
              ),
            ),
          ),
      ],
    );
  }
}

/// The daily calories and the grams of protein, carbs, and fat.
class _GoalTargets extends StatelessWidget {
  const new({required this.goal});

  final ProgressGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accents = MetricAccentColors.of(context);
    final whole = _GoalFormats.of(context).whole;
    final goalKcal = goal.dailyKcalGoal;
    final macros = goal.macroTarget;
    if (goalKcal == null) {
      return Text(l10n.progressGoalNone, style: theme.textTheme.bodyMedium);
    }
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.progressGoalAverageKcal(whole.format(goalKcal)),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (macros != null)
          for (final (color, name, grams) in [
            (accents.protein, l10n.caloriesProteinLabel, macros.proteinGrams),
            (accents.carbs, l10n.caloriesCarbsLabel, macros.carbsGrams),
            (accents.fat, l10n.caloriesFatLabel, macros.fatGrams),
          ])
            _MacroGrams(
              color: color,
              semanticLabel: name,
              grams: whole.format(grams),
            ),
      ],
    );
  }
}

class _MacroGrams extends StatelessWidget {
  const new({
    required this.color,
    required this.semanticLabel,
    required this.grams,
  });

  final Color color;
  final String semanticLabel;
  final String grams;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!.progressGrams(grams);
    return Semantics(
      label: '$semanticLabel $text',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          SizedBox.square(
            dimension: AppProgress.legendSwatch,
            child: ColoredBox(color: color),
          ),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
