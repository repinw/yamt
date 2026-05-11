import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Selectable activity-level list for the calorie-goal calculator.
class CalorieGoalCalculatorActivityLevelSelector extends StatelessWidget {
  /// The calorie goal calculator activity level selector.
  const CalorieGoalCalculatorActivityLevelSelector({
    required this.selectedOption,
    required this.onSelected,
    super.key,
  });

  /// The selected option.
  final CalorieActivityLevelOption selectedOption;

  /// The on selected.
  final ValueChanged<CalorieActivityLevelOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      key: CalorieGoalCalculatorSheetKeys.activityLevelOptions,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.caloriesCalculatorActivityLevelHelp,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final option in CalorieActivityLevelOption.values) ...[
          _ActivityLevelOptionCard(
            option: option,
            isSelected: option == selectedOption,
            title: _activityLevelTitle(l10n, option),
            description: _activityLevelDescription(l10n, option),
            onTap: () => onSelected(option),
          ),
          if (option != CalorieActivityLevelOption.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  String _activityLevelTitle(
    AppLocalizations l10n,
    CalorieActivityLevelOption option,
  ) {
    return switch (option) {
      CalorieActivityLevelOption.none =>
        l10n.caloriesCalculatorActivityLevelNoneTitle,
      CalorieActivityLevelOption.low =>
        l10n.caloriesCalculatorActivityLevelLowTitle,
      CalorieActivityLevelOption.medium =>
        l10n.caloriesCalculatorActivityLevelMediumTitle,
      CalorieActivityLevelOption.high =>
        l10n.caloriesCalculatorActivityLevelHighTitle,
      CalorieActivityLevelOption.extreme =>
        l10n.caloriesCalculatorActivityLevelExtremeTitle,
    };
  }

  String _activityLevelDescription(
    AppLocalizations l10n,
    CalorieActivityLevelOption option,
  ) {
    return switch (option) {
      CalorieActivityLevelOption.none =>
        l10n.caloriesCalculatorActivityLevelNoneDescription,
      CalorieActivityLevelOption.low =>
        l10n.caloriesCalculatorActivityLevelLowDescription,
      CalorieActivityLevelOption.medium =>
        l10n.caloriesCalculatorActivityLevelMediumDescription,
      CalorieActivityLevelOption.high =>
        l10n.caloriesCalculatorActivityLevelHighDescription,
      CalorieActivityLevelOption.extreme =>
        l10n.caloriesCalculatorActivityLevelExtremeDescription,
    };
  }
}

class _ActivityLevelOptionCard extends StatelessWidget {
  const _ActivityLevelOptionCard({
    required this.option,
    required this.isSelected,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final CalorieActivityLevelOption option;
  final bool isSelected;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        key: CalorieGoalCalculatorSheetKeys.activityLevelOption(option.name),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: AppInsets.card,
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
