import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Button that toggles between stock and history views on inventory page.
class InventoryViewToggleButton extends StatelessWidget {
  /// Creates an inventory view toggle button.
  const InventoryViewToggleButton({
    required this.isShowingStock,
    required this.onToggle,
    super.key,
  });

  /// Whether current view is stock.
  final bool isShowingStock;

  /// Callback when button is pressed.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: isShowingStock
          ? l10n.inventoryViewHistory
          : l10n.inventoryViewStock,
      onPressed: onToggle,
      icon: Icon(
        isShowingStock ? Icons.history_rounded : Icons.inventory_2_outlined,
      ),
    );
  }
}
