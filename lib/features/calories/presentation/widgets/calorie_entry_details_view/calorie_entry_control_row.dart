import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_compact_field_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_logged_day_button.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_meal_type_dropdown.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact row for editing the logged day and meal type.
class CalorieEntryControlRow extends StatelessWidget {
  /// Creates the calorie entry detail control row.
  const CalorieEntryControlRow({
    required this.isSaving,
    required this.selectedMealType,
    required this.selectedLoggedAt,
    required this.onPickLoggedAt,
    required this.onMealTypeChanged,
    super.key,
  });

  /// Whether a mutation is in flight.
  final bool isSaving;

  /// Currently selected meal type.
  final MealType selectedMealType;

  /// Currently selected logged day/time.
  final DateTime selectedLoggedAt;

  /// Called when changing the logged day.
  final VoidCallback onPickLoggedAt;

  /// Called when changing the meal type.
  final ValueChanged<MealType> onMealTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        final dayCard = CalorieEntryCompactFieldCard(
          label: l10n.preparedMealDiaryDayLabel,
          child: CalorieEntryLoggedDayButton(
            loggedAt: selectedLoggedAt,
            isEnabled: !isSaving,
            onPressed: onPickLoggedAt,
            material: material,
          ),
        );
        final mealCard = CalorieEntryCompactFieldCard(
          label: l10n.caloriesEntryMealLabel,
          child: CalorieEntryMealTypeDropdown(
            selectedMealType: selectedMealType,
            isEnabled: !isSaving,
            onMealTypeChanged: onMealTypeChanged,
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              dayCard,
              const SizedBox(height: AppSpacing.sm),
              mealCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: dayCard),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: mealCard),
          ],
        );
      },
    );
  }
}
