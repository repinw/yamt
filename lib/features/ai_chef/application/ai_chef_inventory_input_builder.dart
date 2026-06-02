import 'package:yamt/features/inventory/domain/inventory_item.dart';

const _maxInventoryIngredients = 40;

/// Builds pantry inventory entries for the AI Chef prompt.
class AiChefInventoryInputBuilder {
  /// Creates the builder.
  const AiChefInventoryInputBuilder();

  /// Returns active inventory entries formatted for prompt input.
  List<String> build(List<InventoryItem> items) {
    return items
        .where(_canUseInventoryItem)
        .map(_formatInventoryItem)
        .where((ingredient) => ingredient.isNotEmpty)
        .take(_maxInventoryIngredients)
        .toList(growable: false);
  }

  /// Returns active inventory names used for UI ingredient matches.
  List<String> buildNames(List<InventoryItem> items) {
    return items
        .where(_canUseInventoryItem)
        .map((item) => item.name.trim())
        .take(_maxInventoryIngredients)
        .toList(growable: false);
  }

  bool _canUseInventoryItem(InventoryItem item) {
    return item.canBeSavedToInventory &&
        !item.isFullyConsumed &&
        item.name.trim().isNotEmpty;
  }

  String _formatInventoryItem(InventoryItem item) {
    final name = item.name.trim();
    final details = <String>[];
    final amount = _formatInventoryAmount(item);
    if (amount != null) {
      details.add('available: $amount');
    }
    final brand = item.brand?.trim();
    if (brand != null && brand.isNotEmpty) {
      details.add('brand: $brand');
    }
    final category = item.category?.trim();
    if (category != null && category.isNotEmpty) {
      details.add('category: $category');
    }
    if (details.isEmpty) {
      return name;
    }
    return '$name (${details.join(', ')})';
  }

  String? _formatInventoryAmount(InventoryItem item) {
    if (item.usesAmountProgress) {
      return _formatProgressAmount(item);
    }
    final weight = item.weight?.trim();
    if (item.quantity > 1 && weight != null && weight.isNotEmpty) {
      return '${item.quantity} x $weight';
    }
    if (weight != null && weight.isNotEmpty) {
      return weight;
    }
    if (item.quantity > 0) {
      return '${item.quantity} x';
    }
    return null;
  }

  String? _formatProgressAmount(InventoryItem item) {
    final unit = item.amountUnit;
    if (unit == null || item.currentAmount <= 0) {
      return null;
    }
    final amount = formatInventoryAmountValue(
      amount: item.currentAmount,
      unit: unit,
      scale: item.amountScale,
    );
    return '$amount ${unit.code}';
  }
}
