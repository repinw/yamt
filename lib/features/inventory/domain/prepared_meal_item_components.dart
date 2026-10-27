import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

/// The foods of a meal, one per Vorrat item. A meal whose item filled two
/// rows holds two components of it; here they count as one, with their
/// amounts and values added up. The row link stays only when both name
/// the same row.
List<PreparedMealComponent> preparedMealComponentsByItem(
  List<PreparedMealComponent> components,
) => [
  for (final group
      in components
          .groupListsBy((component) => component.inventoryItemId)
          .values)
    group.reduce(
      (merged, next) => merged.copyWith(
        usedAmount: merged.usedAmount + next.usedAmount,
        totalKcal: merged.totalKcal + next.totalKcal,
        totalProtein: merged.totalProtein + next.totalProtein,
        totalCarbs: merged.totalCarbs + next.totalCarbs,
        totalFat: merged.totalFat + next.totalFat,
        pendingRecipeIngredient:
            merged.pendingRecipeIngredient == next.pendingRecipeIngredient
            ? merged.pendingRecipeIngredient
            : null,
      ),
    ),
];

/// The components [group] of one Vorrat item scaled together to
/// [usedAmount] in all, each keeping its share and its row. The last one
/// takes what rounding leaves.
List<PreparedMealComponent> scaledItemComponents(
  List<PreparedMealComponent> group,
  int usedAmount,
) {
  final total = group.fold<int>(0, (sum, c) => sum + c.usedAmount);
  final scaled = <PreparedMealComponent>[];
  var left = usedAmount;
  for (final (index, component) in group.indexed) {
    final share = index == group.length - 1 || total < 1
        ? left
        : (usedAmount * component.usedAmount / total).round();
    left -= share;
    scaled.add(scaledPreparedMealComponent(component, share));
  }
  return scaled;
}

/// [component] with [amount] and its values scaled to it.
PreparedMealComponent scaledPreparedMealComponent(
  PreparedMealComponent component,
  int amount,
) {
  if (component.usedAmount < 1) {
    return component.copyWith(usedAmount: amount);
  }
  final multiplier = amount / component.usedAmount;
  return component.copyWith(
    usedAmount: amount,
    totalKcal: component.totalKcal * multiplier,
    totalProtein: component.totalProtein * multiplier,
    totalCarbs: component.totalCarbs * multiplier,
    totalFat: component.totalFat * multiplier,
  );
}
