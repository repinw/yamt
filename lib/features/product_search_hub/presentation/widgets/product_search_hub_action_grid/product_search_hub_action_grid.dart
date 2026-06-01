import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Quick actions shown above product search.
class ProductSearchHubActionGrid extends StatelessWidget {
  /// Creates product search hub quick actions.
  const ProductSearchHubActionGrid({
    required this.showDiarySourceActions,
    super.key,
    this.onBarcodePressed,
    this.onAiPressed,
    this.onReceiptPressed,
    this.onInventoryPressed,
    this.onMealPressed,
    this.onCreateOwnPressed,
  });

  /// Whether diary-only source actions are visible.
  final bool showDiarySourceActions;

  /// Barcode action.
  final VoidCallback? onBarcodePressed;

  /// AI action.
  final VoidCallback? onAiPressed;

  /// Receipt source action.
  final VoidCallback? onReceiptPressed;

  /// Inventory source action.
  final VoidCallback? onInventoryPressed;

  /// Meal source action.
  final VoidCallback? onMealPressed;

  /// Create own product action.
  final VoidCallback? onCreateOwnPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 3;
        final itemWidth =
            (constraints.maxWidth - (AppSpacing.md * (columnCount - 1))) /
            columnCount;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ProductSearchHubActionButton(
              key: const Key('product_search_hub_barcode_action'),
              icon: Icons.qr_code_scanner_rounded,
              label: l10n.productSearchHubBarcodeAction,
              width: itemWidth,
              onPressed: onBarcodePressed,
            ),
            _ProductSearchHubActionButton(
              key: const Key('product_search_hub_ai_action'),
              icon: Icons.auto_awesome_rounded,
              label: l10n.productSearchHubAiAction,
              width: itemWidth,
              onPressed: onAiPressed,
            ),
            if (showDiarySourceActions) ...[
              _ProductSearchHubActionButton(
                key: const Key('product_search_hub_receipt_action'),
                icon: Icons.receipt_long_rounded,
                label: l10n.productSearchHubReceiptAction,
                width: itemWidth,
                onPressed: onReceiptPressed,
              ),
              _ProductSearchHubActionButton(
                key: const Key('product_search_hub_inventory_action'),
                icon: Icons.inventory_2_rounded,
                label: l10n.productSearchHubInventoryAction,
                width: itemWidth,
                onPressed: onInventoryPressed,
              ),
              _ProductSearchHubActionButton(
                key: const Key('product_search_hub_meal_action'),
                icon: Icons.restaurant_menu_rounded,
                label: l10n.productSearchHubMealAction,
                width: itemWidth,
                onPressed: onMealPressed,
              ),
            ],
            _ProductSearchHubActionButton(
              key: const Key('product_search_hub_create_own_action'),
              icon: Icons.edit_note_rounded,
              label: l10n.productSearchHubCreateOwnAction,
              width: itemWidth,
              onPressed: onCreateOwnPressed,
            ),
          ],
        );
      },
    );
  }
}

class _ProductSearchHubActionButton extends StatelessWidget {
  const _ProductSearchHubActionButton({
    required this.icon,
    required this.label,
    required this.width,
    super.key,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final double width;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 88,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
