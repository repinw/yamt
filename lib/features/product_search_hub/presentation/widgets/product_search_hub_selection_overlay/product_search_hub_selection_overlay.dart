import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _productSearchHubSelectionOverlayCountSize = 48.0;

/// Compact selected-products overlay shown above the hub content.
class ProductSearchHubSelectionOverlay extends StatelessWidget {
  /// Creates selected-products overlay.
  const ProductSearchHubSelectionOverlay({
    required this.productCount,
    required this.isSaving,
    required this.onCountPressed,
    required this.onSubmitPressed,
    super.key,
  });

  /// Number of selected products.
  final int productCount;

  /// Whether selected products are being saved.
  final bool isSaving;

  /// Opens selected product details.
  final VoidCallback onCountPressed;

  /// Closes the hub after already-saved products are accepted.
  final VoidCallback onSubmitPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      key: const Key('product_search_hub_selection_overlay'),
      elevation: 8,
      shadowColor: colors.shadow.withValues(alpha: 0.24),
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _productSearchHubSelectionOverlayCountSize,
              child: OutlinedButton(
                key: const Key('product_search_hub_cart_count_button'),
                onPressed: onCountPressed,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  '$productCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                key: const Key('product_search_hub_cart_add_button'),
                onPressed: isSaving ? null : onSubmitPressed,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: AppSizes.inlineProgressIndicator,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.productSearchHubCartAddAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet listing selected products.
class ProductSearchHubSelectionSheet extends StatelessWidget {
  /// Creates selected-products sheet.
  const ProductSearchHubSelectionSheet({
    required this.items,
    required this.isSaving,
    required this.onRemovePressed,
    super.key,
  });

  /// Selected inventory items.
  final List<InventoryItem> items;

  /// Whether products are being changed.
  final bool isSaving;

  /// Removes a product from the current inventory insert session.
  final Future<void> Function(InventoryItem item) onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.productSearchHubCartTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.separated(
                  key: const Key('product_search_hub_selection_sheet_list'),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: AppSpacing.md);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InventoryProductCandidateTile(
                      key: Key(
                        'product_search_hub_selection_sheet_${item.id}',
                      ),
                      name: item.name,
                      brand: item.brand,
                      imageUrl: item.imageUrl,
                      packageWeight: item.weight,
                      nutrition: item.nutrition,
                      trailing: IconButton(
                        key: Key(
                          'product_search_hub_cart_remove_${item.id}',
                        ),
                        tooltip: l10n.productSearchHubCartRemoveAction,
                        onPressed: isSaving
                            ? null
                            : () {
                                unawaited(onRemovePressed(item));
                              },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
