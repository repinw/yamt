import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_recent_item_key.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _productSearchHubRecentlySelectedLogName =
    'ProductSearchHubRecentlySelectedTab';

/// Recently selected manual products for the product search hub.
@Dependencies([manualProductRecentItemsService])
class ProductSearchHubRecentlySelectedTab extends ConsumerStatefulWidget {
  /// Creates recently selected product tab.
  const ProductSearchHubRecentlySelectedTab({
    required this.selectedProductKeys,
    required this.onProductPressed,
    super.key,
  });

  /// Selected product keys.
  final Set<String> selectedProductKeys;

  /// Called when a recent product is selected.
  final ValueChanged<InventoryItem> onProductPressed;

  @override
  ConsumerState<ProductSearchHubRecentlySelectedTab> createState() {
    return _ProductSearchHubRecentlySelectedTabState();
  }
}

class _ProductSearchHubRecentlySelectedTabState
    extends ConsumerState<ProductSearchHubRecentlySelectedTab> {
  var _items = const <InventoryItem>[];
  var _isLoading = true;
  var _hasLoadFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadItems());
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _hasLoadFailed = false;
    });

    try {
      final recentItemsService = ref.read(
        manualProductRecentItemsServiceProvider,
      );
      final items = await recentItemsService.readRecentItems();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load recently selected products.',
        name: _productSearchHubRecentlySelectedLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasLoadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return _ProductSearchHubRecentlySelectedLoading(
        label: l10n.productSearchHubRecentlySelectedLoading,
      );
    }

    if (_hasLoadFailed) {
      return _ProductSearchHubRecentlySelectedError(
        message: l10n.productSearchHubRecentlySelectedLoadFailed,
        retryLabel: l10n.productSearchHubRecentlySelectedRetryAction,
        onRetry: () {
          unawaited(_loadItems());
        },
      );
    }

    if (_items.isEmpty) {
      return _ProductSearchHubRecentlySelectedEmpty(
        message: l10n.productSearchHubRecentlySelectedEmptyState,
      );
    }

    return _ProductSearchHubRecentlySelectedList(
      items: _items,
      selectedProductKeys: widget.selectedProductKeys,
      onProductPressed: widget.onProductPressed,
    );
  }
}

class _ProductSearchHubRecentlySelectedLoading extends StatelessWidget {
  const _ProductSearchHubRecentlySelectedLoading({required this.label});

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
  const _ProductSearchHubRecentlySelectedError({
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
            key: const Key(
              'product_search_hub_recently_selected_retry_button',
            ),
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
  const _ProductSearchHubRecentlySelectedEmpty({required this.message});

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
  const _ProductSearchHubRecentlySelectedList({
    required this.items,
    required this.selectedProductKeys,
    required this.onProductPressed,
  });

  final List<InventoryItem> items;
  final Set<String> selectedProductKeys;
  final ValueChanged<InventoryItem> onProductPressed;

  @override
  Widget build(BuildContext context) {
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
