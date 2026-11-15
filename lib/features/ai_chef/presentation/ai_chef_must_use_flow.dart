import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_must_use_sheet.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Loads the pickable Vorrat, oldest first, with [loadItems], lets the user
/// pick the items that must go into the recipe, and returns them in that
/// order. Returns null when the
/// user closes the sheet. A Vorrat that cannot be loaded throws, so the
/// caller can say so where the user looks.
Future<List<InventoryItem>?> pickAiChefMustUseItems(
  BuildContext context, {
  required Future<List<InventoryItem>> Function() loadItems,
  required List<InventoryItem> picked,
  required DateTime today,
}) async {
  final items = await loadItems();
  final ids = {for (final item in items) item.id};
  if (!context.mounted) {
    return null;
  }
  // A pick eaten since then is no longer offered or counted.
  final selected = await AiChefMustUseSheet.show(
    context,
    items: items,
    selectedIds: {
      for (final item in picked)
        if (ids.contains(item.id)) item.id,
    },
    today: today,
  );
  if (selected == null) {
    return null;
  }
  return [
    for (final item in items)
      if (selected.contains(item.id)) item,
  ];
}
