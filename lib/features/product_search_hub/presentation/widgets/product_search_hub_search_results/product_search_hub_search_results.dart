import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_result_quality.dart';
import 'package:yamt/features/inventory/presentation/utils/'
    'off_product_nutrition_grade_extension.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product search hub result list.
class ProductSearchHubSearchResults extends StatelessWidget {
  /// Creates product search hub search results.
  const ProductSearchHubSearchResults({
    required this.results,
    required this.isSearching,
    required this.hasFailed,
    required this.onRetry,
    required this.onCreateOwnPressed,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.onResultSelected,
    super.key,
  });

  /// Search results.
  final List<OffProductSearchResult> results;

  /// Whether search request is running.
  final bool isSearching;

  /// Whether last search request failed.
  final bool hasFailed;

  /// Retry callback.
  final VoidCallback onRetry;

  /// Opens custom product creation.
  final VoidCallback onCreateOwnPressed;

  /// Keyboard dismissal behavior for the internal result list.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Called when a result is selected.
  final ValueChanged<OffProductSearchResult>? onResultSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (hasFailed) {
      return _ProductSearchHubSearchError(
        message: l10n.productSearchHubSearchLoadFailed,
        retryLabel: l10n.productSearchHubSearchRetryAction,
        onRetry: onRetry,
      );
    }

    if (isSearching && results.isEmpty) {
      return _ProductSearchHubSearchLoading(
        label: l10n.productSearchHubSearchLoading,
      );
    }

    if (results.isEmpty) {
      return _ProductSearchHubSearchEmpty(
        message: l10n.productSearchHubSearchEmptyState,
        createLabel: l10n.productSearchHubCreateProductAction,
        onCreate: onCreateOwnPressed,
      );
    }

    return _ProductSearchHubSearchResultList(
      results: results,
      showLoading: isSearching,
      keyboardDismissBehavior: keyboardDismissBehavior,
      onResultSelected: onResultSelected,
    );
  }
}

class _ProductSearchHubSearchLoading extends StatelessWidget {
  const _ProductSearchHubSearchLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        child: const CircularProgressIndicator(
          key: Key('product_search_hub_search_loading'),
        ),
      ),
    );
  }
}

class _ProductSearchHubSearchError extends StatelessWidget {
  const _ProductSearchHubSearchError({
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
            key: const Key('product_search_hub_search_error'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('product_search_hub_search_retry_button'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _ProductSearchHubSearchEmpty extends StatelessWidget {
  const _ProductSearchHubSearchEmpty({
    required this.message,
    required this.createLabel,
    required this.onCreate,
  });

  final String message;
  final String createLabel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            key: const Key('product_search_hub_search_empty_state'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('product_search_hub_search_create_product_button'),
            onPressed: onCreate,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(createLabel),
          ),
        ],
      ),
    );
  }
}

class _ProductSearchHubSearchResultList extends StatelessWidget {
  const _ProductSearchHubSearchResultList({
    required this.results,
    required this.showLoading,
    required this.keyboardDismissBehavior,
    required this.onResultSelected,
  });

  final List<OffProductSearchResult> results;
  final bool showLoading;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final ValueChanged<OffProductSearchResult>? onResultSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        ListView.separated(
          key: const Key('product_search_hub_search_result_list'),
          keyboardDismissBehavior: keyboardDismissBehavior,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          physics: const ClampingScrollPhysics(),
          primary: false,
          itemCount: results.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: AppSpacing.md);
          },
          itemBuilder: (context, index) {
            final result = results[index];
            return SizedBox(
              width: double.infinity,
              child: InventoryProductCandidateTile(
                key: Key('product_search_hub_search_result_${result.code}'),
                name: result.name,
                brand: result.brand,
                imageUrl: result.imageUrl,
                packageWeight: result.packageWeight,
                nutrition: result.nutrition,
                statusLabel: gradeOffProductNutrition(
                  result.nutrition,
                ).localizedLabel(l10n),
                onTap: onResultSelected == null
                    ? null
                    : () {
                        onResultSelected!(result);
                      },
              ),
            );
          },
        ),
        if (showLoading) const LinearProgressIndicator(),
      ],
    );
  }
}
