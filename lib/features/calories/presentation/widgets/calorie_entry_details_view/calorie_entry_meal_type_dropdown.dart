import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Meal type selector for calorie entry details.
class CalorieEntryMealTypeDropdown extends StatelessWidget {
  /// Creates a meal type selector.
  const CalorieEntryMealTypeDropdown({
    required this.selectedMealType,
    required this.isEnabled,
    required this.onMealTypeChanged,
    super.key,
  });

  /// Currently selected meal type.
  final MealType selectedMealType;

  /// Whether selection is enabled.
  final bool isEnabled;

  /// Called when the meal type changes.
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: AppDropdownButton<MealType>(
        key: CalorieEntryDetailKeys.mealSelector,
        value: selectedMealType,
        isDense: true,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        dropdownColor: colors.surfaceContainerHigh,
        icon: Icon(
          Icons.expand_more_rounded,
          color: colors.onSurfaceVariant,
          size: 20,
        ),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isEnabled
              ? colors.onSurface
              : colors.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
        items: MealType.sectionOrder
            .map((mealType) {
              return DropdownMenuItem<MealType>(
                value: mealType,
                child: Text(
                  mealType.localizedName(l10n),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            })
            .toList(growable: false),
        onChanged: isEnabled
            ? (value) {
                if (value == null) {
                  return;
                }
                onMealTypeChanged(value);
              }
            : null,
      ),
    );
  }
}
