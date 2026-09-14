import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eat-now date and meal type controls for AI search.
class AiEatWhenSection extends StatelessWidget {
  /// Creates eat-now controls.
  const AiEatWhenSection({
    required this.isToday,
    required this.label,
    required this.selectedMealType,
    required this.onPickLoggedAt,
    required this.onMealTypeSelected,
    super.key,
  });

  /// Whether selected date is today.
  final bool isToday;

  /// Selected date label.
  final String? label;

  /// Selected meal type.
  final MealType selectedMealType;

  /// Opens date picker.
  final VoidCallback onPickLoggedAt;

  /// Called when meal type changes.
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isToday)
          AiEatWhenCard(
            label: label,
            isToday: isToday,
            onPressed: onPickLoggedAt,
          )
        else
          Expanded(
            child: AiEatWhenCard(
              label: label,
              isToday: isToday,
              onPressed: onPickLoggedAt,
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AiMealTypeSelector(
            selectedMealType: selectedMealType,
            onMealTypeSelected: onMealTypeSelected,
          ),
        ),
      ],
    );
  }
}

/// Date selection card for AI eat-now flow.
class AiEatWhenCard extends StatelessWidget {
  /// Creates a date selection card.
  const AiEatWhenCard({
    required this.label,
    required this.isToday,
    required this.onPressed,
    super.key,
  });

  /// Selected date label.
  final String? label;

  /// Whether selected date is today.
  final bool isToday;

  /// Opens date picker.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Widget content;
    if (label case final String text when !isToday) {
      content = Row(
        key: const Key('manual_product_ai_logged_at_labeled'),
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurfaceVariant,
          ),
        ],
      );
    } else {
      content = Row(
        key: const Key('manual_product_ai_logged_at_compact'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurfaceVariant,
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        key: const Key('manual_product_ai_logged_at_button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Meal type selector for AI eat-now flow.
class AiMealTypeSelector extends StatelessWidget {
  /// Creates a meal type selector.
  const AiMealTypeSelector({
    required this.selectedMealType,
    required this.onMealTypeSelected,
    super.key,
  });

  /// Selected meal type.
  final MealType selectedMealType;

  /// Called when meal type changes.
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_rounded, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: AppDropdownButton<MealType>(
                value: selectedMealType,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                dropdownColor: colors.surfaceContainerHigh,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: colors.onSurfaceVariant,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                items: MealType.sectionOrder
                    .map((mealType) {
                      return DropdownMenuItem<MealType>(
                        value: mealType,
                        child: Text(
                          _manualProductAiMealTypeLabel(context, mealType),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  onMealTypeSelected(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _manualProductAiMealTypeLabel(BuildContext context, MealType mealType) {
  final l10n = AppLocalizations.of(context)!;
  return switch (mealType) {
    MealType.breakfast => l10n.caloriesMealBreakfast,
    MealType.lunch => l10n.caloriesMealLunch,
    MealType.dinner => l10n.caloriesMealDinner,
    MealType.snack => l10n.caloriesMealSnack,
  };
}
