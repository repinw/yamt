import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_style.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory list mode.
enum InventoryListMode {
  /// By receipt.
  byReceipt,

  /// All items.
  allItems,
}

/// Defines inventory list mode toggle.
class InventoryListModeToggle extends StatelessWidget {
  /// The inventory list mode toggle.
  const InventoryListModeToggle({
    required this.mode,
    required this.l10n,
    required this.onModeChanged,
    super.key,
    this.enabled = true,
  });

  /// The mode.
  final InventoryListMode mode;

  /// The l10n.
  final AppLocalizations l10n;

  /// The on mode changed.
  final ValueChanged<InventoryListMode> onModeChanged;

  /// The enabled.
  final bool enabled;

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
      onSelectionChanged: enabled
          ? (selection) {
              if (selection.isEmpty) {
                return;
              }
              onModeChanged(selection.first);
            }
          : null,
    );
  }
}
