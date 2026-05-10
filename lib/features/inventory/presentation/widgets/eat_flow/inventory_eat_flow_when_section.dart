import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_meal_type_selector.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_when_card.dart';

/// Shared date/meal section for eat flows.
class InventoryEatFlowWhenSection extends StatelessWidget {
  /// Creates date/meal row.
  const InventoryEatFlowWhenSection({
    required this.isToday,
    required this.label,
    required this.selectedMealType,
    required this.loggedAtButtonKey,
    required this.loggedAtCompactKey,
    required this.loggedAtLabeledKey,
    required this.onPickLoggedAt,
    required this.onMealTypeSelected,
    super.key,
  });

  /// Whether selected day is today.
  final bool isToday;

  /// Date label.
  final String? label;

  /// Selected meal type.
  final MealType selectedMealType;

  /// Logged-at button key.
  final Key loggedAtButtonKey;

  /// Compact state key.
  final Key loggedAtCompactKey;

  /// Labeled state key.
  final Key loggedAtLabeledKey;

  /// Date picker callback.
  final VoidCallback onPickLoggedAt;

  /// Meal type callback.
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isToday)
          InventoryEatFlowWhenCard(
            label: label,
            isToday: isToday,
            buttonKey: loggedAtButtonKey,
            compactKey: loggedAtCompactKey,
            labeledKey: loggedAtLabeledKey,
            onPressed: onPickLoggedAt,
          )
        else
          Expanded(
            child: InventoryEatFlowWhenCard(
              label: label,
              isToday: isToday,
              buttonKey: loggedAtButtonKey,
              compactKey: loggedAtCompactKey,
              labeledKey: loggedAtLabeledKey,
              onPressed: onPickLoggedAt,
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: InventoryEatFlowMealTypeSelector(
            selectedMealType: selectedMealType,
            onMealTypeSelected: onMealTypeSelected,
          ),
        ),
      ],
    );
  }
}
