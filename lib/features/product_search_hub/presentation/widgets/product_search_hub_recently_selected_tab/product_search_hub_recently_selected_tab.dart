import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'product_search_hub_recent_items.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_recent_item_key.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_candidate_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _productSearchHubRecentlySelectedLogName =
    'ProductSearchHubRecentlySelectedTab';

/// Recently selected manual products for the product search hub.
class ProductSearchHubRecentlySelectedTab extends ConsumerWidget {
  /// Creates recently selected product tab.
  const new({
    required this.selectedProductKeys,
    required this.onProductPressed,
    this.onProductCopied,
    super.key,
  });

  /// Selected product keys.
  final Set<String> selectedProductKeys;

  /// Called when a recent product is selected.
  final ValueChanged<InventoryItem> onProductPressed;

  /// Called when a recent product is copied as template.
  final ValueChanged<InventoryItem>? onProductCopied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(productSearchHubRecentItemsProvider, (previous, next) {
      if (next case AsyncError(:final error, :final stackTrace)) {
        log(
          'Failed to load recently selected products.',
          name: _productSearchHubRecentlySelectedLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    });

    return ref
        .watch(productSearchHubRecentItemsProvider)
        .when(
          loading: () => _ProductSearchHubRecentlySelectedLoading(
            label: l10n.productSearchHubRecentlySelectedLoading,
          ),
          error: (error, stackTrace) => _ProductSearchHubRecentlySelectedError(
            message: l10n.productSearchHubRecentlySelectedLoadFailed,
            retryLabel: l10n.productSearchHubRecentlySelectedRetryAction,
            onRetry: () => ref.invalidate(productSearchHubRecentItemsProvider),
          ),
          data: (items) => items.isEmpty
              ? _ProductSearchHubRecentlySelectedEmpty(
                  message: l10n.productSearchHubRecentlySelectedEmptyState,
                )
              : _ProductSearchHubRecentlySelectedList(
                  items: items,
                  selectedProductKeys: selectedProductKeys,
                  onProductPressed: onProductPressed,
                  onProductCopied: onProductCopied,
                ),
        );
  }
}

class _ProductSearchHubRecentlySelectedLoading extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        child: const CircularProgressIndicator(
          key: Key('product_search_hub_recently_selected_loading'),
        ),
      ),
    );
  }
}

class _ProductSearchHubRecentlySelectedError extends StatelessWidget {
  const new({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            key: const Key('product_search_hub_recently_selected_error'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('product_search_hub_recently_selected_retry_button'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _ProductSearchHubRecentlySelectedEmpty extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        key: const Key('product_search_hub_recently_selected_empty_state'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ProductSearchHubRecentlySelectedList extends StatelessWidget {
  const new({
    required this.items,
    required this.selectedProductKeys,
    required this.onProductPressed,
    this.onProductCopied,
  });

  final List<InventoryItem> items;
  final Set<String> selectedProductKeys;
  final ValueChanged<InventoryItem> onProductPressed;
  final ValueChanged<InventoryItem>? onProductCopied;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView.separated(
      key: const Key('product_search_hub_recently_selected_list'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: items.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: AppSpacing.md);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedProductKeys.contains(
          productSearchHubRecentItemSelectionKey(item),
        );
        return SizedBox(
          width: double.infinity,
          child: InventoryProductCandidateTile(
            key: Key('product_search_hub_recently_selected_item_${item.id}'),
            name: item.name,
            brand: item.brand,
            imageUrl: item.imageUrl,
            packageWeight: item.weight,
            nutrition: item.nutrition,
            onCopy: onProductCopied == null
                ? null
                : () {
                    onProductCopied!(item);
                  },
            copyTooltip: l10n.productSearchHubCopyActionTooltip,
            copyButtonKey: Key(
              'product_search_hub_recently_selected_copy_${item.id}',
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    key: Key(
                      'product_search_hub_recently_selected_selected_icon',
                    ),
                  )
                : null,
            onTap: () {
              onProductPressed(item);
            },
          ),
        );
      },
    );
  }
}
