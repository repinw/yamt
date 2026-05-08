import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/domain/meal_type.dart';

/// Scoped quick-eat settings for manual inventory add flows.
class InventoryManualAddQuickEatConfig {
  /// Creates quick-eat settings.
  const InventoryManualAddQuickEatConfig({
    this.quickEatOnly = false,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  /// Default non quick-eat settings.
  static const standard = InventoryManualAddQuickEatConfig();

  /// Whether only eat actions should be shown.
  final bool quickEatOnly;

  /// Preselected meal type for eat flow.
  final MealType? preselectedMealType;

  /// Preselected logged-at for eat flow.
  final DateTime? preselectedLoggedAt;
}

/// Scoped provider for quick-eat settings in manual add subtrees.
final inventoryManualAddQuickEatConfigProvider =
    Provider<InventoryManualAddQuickEatConfig>(
      (ref) => InventoryManualAddQuickEatConfig.standard,
      dependencies: const [],
    );
