import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_style.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum InventoryListMode { byReceipt, allItems }

class InventoryListModeToggle extends StatelessWidget {
  const InventoryListModeToggle({
    super.key,
    required this.mode,
    required this.l10n,
    required this.onModeChanged,
  });

  final InventoryListMode mode;
  final AppLocalizations l10n;
  final ValueChanged<InventoryListMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<InventoryListMode>(
      expandedInsets: AppInsets.zero,
      showSelectedIcon: false,
      style: inventorySegmentedButtonStyle(context),
      segments: [
        ButtonSegment<InventoryListMode>(
          value: InventoryListMode.allItems,
          label: Text(l10n.inventoryListModeAllItems),
        ),
        ButtonSegment<InventoryListMode>(
          value: InventoryListMode.byReceipt,
          label: Text(l10n.inventoryListModeByReceipt),
        ),
      ],
      selected: <InventoryListMode>{mode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onModeChanged(selection.first);
      },
    );
  }
}
