import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';

/// Defines inventory receipt groups sliver.
class InventoryReceiptGroupsSliver extends ConsumerWidget {
  /// The inventory receipt groups sliver.
  const new({
    required this.groups,
    required this.dateFormat,
    required this.selection,
    super.key,
  });

  /// The groups.
  final List<InventoryReceiptGroup> groups;

  /// The date format.
  final DateFormat dateFormat;

  /// Inventory item selection options.
  final ReceiptGroupSelectionOptions selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = responsivePageHorizontalPadding(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        homeShellPageBottomPadding(context),
      ),
      sliver: SliverList.builder(
        itemCount: groups.length,
        itemBuilder: (_, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            child: ReceiptGroupTile(
              group: group,
              dateFormat: dateFormat,
              selection: selection,
              // The list's context, not a row's: the hub's work goes on
              // after it closes, also when the row left the list meanwhile.
              onOpenItem: (item) => unawaited(
                InventoryItemHubFlow.open(
                  context: context,
                  ref: ref,
                  item: item,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
