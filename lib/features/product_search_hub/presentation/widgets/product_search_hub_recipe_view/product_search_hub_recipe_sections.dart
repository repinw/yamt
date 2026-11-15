import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_coordinator.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "FÜR 250 G MEHL" and "Was für Mehl hast du?".
class RecipeHead extends StatelessWidget {
  /// Creates the head of [args]' line.
  const new({required this.args, super.key});

  /// Route args with the recipe line.
  final ProductSearchHubRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final food = args.initialQuery?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recipeFoodFor(args.ingredient ?? '').toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: AppGraphit.kickerTracking,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            food.isEmpty
                ? l10n.recipeFoodTitleFallback
                : l10n.recipeFoodTitle(food),
            style: textTheme.headlineMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The line "oder aussuchen" between the scan button and the search.
class RecipeOrPick extends StatelessWidget {
  /// Creates the line.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final rule = Expanded(child: Divider(color: colors.rule));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        children: [
          rule,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              AppLocalizations.of(context)!.recipeFoodOrPick,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.muted, fontWeight: FontWeight.w600),
            ),
          ),
          rule,
        ],
      ),
    );
  }
}

/// The catalog's foods for the search, or why there are none.
class RecipeCatalogHits extends StatelessWidget {
  /// Creates the hits of [search].
  const new({
    required this.search,
    required this.isOffline,
    required this.onResultSelected,
    super.key,
  });

  /// Key of the catalog food [code].
  static Key resultKey(String code) =>
      Key('product_search_hub_recipe_result_$code');

  /// The running search.
  final ProductSearchHubSearchCoordinator search;

  /// Whether the device is offline.
  final bool isOffline;

  /// Picks a catalog food.
  final ValueChanged<OffProductSearchResult> onResultSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = search.results;
    if (!search.hasSearchQuery) return const SliverToBoxAdapter();
    if (search.hasFailed && !isOffline) {
      return SliverToBoxAdapter(
        child: RecipeListNote(
          text: l10n.productSearchHubSearchLoadFailed,
          action: TextButton(
            onPressed: search.retrySearch,
            child: Text(l10n.productSearchHubSearchRetryAction),
          ),
        ),
      );
    }
    if (search.isSearching && results.isEmpty) {
      return const SliverToBoxAdapter(child: LinearProgressIndicator());
    }
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: RecipeListNote(
          text: isOffline
              ? l10n.productSearchHubSearchOfflineState
              : l10n.productSearchHubSearchEmptyState,
        ),
      );
    }
    return SliverList.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final brand = result.brand?.trim() ?? '';
        final size = result.packageWeight?.trim() ?? '';
        return RecipeFoodRow(
          key: resultKey(result.code),
          title: result.name,
          subtitle: brand.isEmpty || size.isEmpty
              ? (brand.isEmpty ? (size.isEmpty ? null : size) : brand)
              : l10n.recipeFoodBrandAndSize(brand, size),
          imageUrl: result.imageUrl,
          onTap: () => onResultSelected(result),
        );
      },
    );
  }
}
