import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_tile.dart';

const _tileColumns = 3;

/// Vorrat entries as flat rows or as a grid of tiles.
///
/// A food opens its item hub and a meal its detail page. In selection mode a
/// tap toggles a food and meals do nothing.
class InventoryEntriesSliver extends ConsumerWidget {
  /// Creates the sliver.
  const new({
    required this.entries,
    required this.viewMode,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onOpenMeal,
    required this.onItemLongPress,
    required this.onSelectionToggle,
    super.key,
  });

  /// Entries in list order.
  final List<InventoryListEntry> entries;

  /// Rows or tiles.
  final InventoryListViewMode viewMode;

  /// Whether the list selects foods.
  final bool isSelectionMode;

  /// Selected food ids.
  final Set<String> selectedItemIds;

  /// Opens the detail page of a meal.
  final ValueChanged<PreparedMeal> onOpenMeal;

  /// Starts the selection with a food.
  final ValueChanged<String> onItemLongPress;

  /// Toggles a food in selection mode.
  final ValueChanged<String> onSelectionToggle;

  /// Key of the list of rows.
  static const listKey = Key('inventory_entries_list');

  /// Key of the grid of tiles.
  static const tilesKey = Key('inventory_entries_tiles');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = responsivePageHorizontalPadding(context);
    final padding = EdgeInsets.fromLTRB(
      horizontalPadding,
      0,
      horizontalPadding,
      homeShellPageBottomPadding(context),
    );

    VoidCallback? onTap(InventoryListEntry entry) => switch (entry) {
      InventoryFoodEntry(:final item) =>
        isSelectionMode
            ? () => onSelectionToggle(item.id)
            : () => unawaited(
                InventoryItemHubFlow.open(
                  context: context,
                  ref: ref,
                  item: item,
                ),
              ),
      InventoryMealEntry(:final meal) =>
        isSelectionMode ? null : () => onOpenMeal(meal),
    };
    VoidCallback? onLongPress(InventoryListEntry entry) =>
        !isSelectionMode && entry is InventoryFoodEntry && !entry.isEmpty
        ? () => onItemLongPress(entry.id)
        : null;

    final planned =
        ref.watch(openPlanDemandProvider).value?.plannedByItemId ??
        const <String, int>{};
    if (viewMode == InventoryListViewMode.tiles) {
      return SliverPadding(
        key: tilesKey,
        padding: padding,
        // Rows of tiles instead of a grid, so a tile grows with large text.
        sliver: SliverList.builder(
          itemCount: (entries.length / _tileColumns).ceil(),
          itemBuilder: (context, row) {
            final start = row * _tileColumns;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    for (
                      var index = start;
                      index < start + _tileColumns;
                      index++
                    )
                      Expanded(
                        child: index < entries.length
                            ? InventoryEntryTile(
                                key: ValueKey(
                                  'inventory_entry_tile_${entries[index].id}',
                                ),
                                entry: entries[index],
                                tiltLeft: index.isEven,
                                isSelected: selectedItemIds.contains(
                                  entries[index].id,
                                ),
                                onTap: onTap(entries[index]),
                                onLongPress: onLongPress(entries[index]),
                                planned: planned[entries[index].id] ?? 0,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return SliverPadding(
      key: listKey,
      padding: padding,
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return InventoryEntryRow(
            key: ValueKey('inventory_entry_row_${entry.id}'),
            entry: entry,
            tiltLeft: index.isEven,
            isSelectionMode: isSelectionMode,
            isSelected: selectedItemIds.contains(entry.id),
            onTap: onTap(entry),
            onLongPress: onLongPress(entry),
            planned: planned[entry.id] ?? 0,
          );
        },
      ),
    );
  }
}
