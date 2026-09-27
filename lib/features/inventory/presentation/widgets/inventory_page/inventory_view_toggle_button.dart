import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header tool that toggles between the stock and history views of the
/// inventory page.
class InventoryViewToggleButton extends StatelessWidget {
  /// Creates an inventory view toggle button.
  const new({required this.isShowingStock, required this.onToggle, super.key});

  /// Whether current view is stock.
  final bool isShowingStock;

  /// Callback when button is pressed.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HomeHeaderTool(
      symbol: Icon(
        isShowingStock ? Icons.history_rounded : Icons.inventory_2_outlined,
      ),
      label: isShowingStock
          ? l10n.inventoryViewHistory
          : l10n.inventoryViewStock,
      onPressed: onToggle,
    );
  }
}
