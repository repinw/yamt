import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_field_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared meal type selector.
class InventoryEatFlowMealTypeSelector extends StatelessWidget {
  /// Creates meal type selector.
  const InventoryEatFlowMealTypeSelector({
    required this.selectedMealType,
    required this.onMealTypeSelected,
    super.key,
  });

  /// Selected meal type.
  final MealType selectedMealType;

  /// Selection callback.
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return InventoryEatFlowFieldCard(
      leadingIcon: Icons.restaurant_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MealType>(
          value: selectedMealType,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          dropdownColor: colors.surfaceContainerHigh,
          icon: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          items: MealType.sectionOrder
              .map((mealType) {
                return DropdownMenuItem<MealType>(
                  value: mealType,
                  child: Text(
                    mealType.localizedName(l10n),
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
    );
  }
}
