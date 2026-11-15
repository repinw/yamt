import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'product_search_hub_stock_foods.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'recipe_food_guess_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_coordinator.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_guess.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_rows.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_recipe_sections.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recipe_view/product_search_hub_stock_sheet.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_bar/product_search_hub_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Welches Mehl hast du?": the food pick for a recipe line. Scanning the
/// pack comes first, then the search with the line's food already in it:
/// the Vorrat's foods first, then the catalog's, as plain rows, and the own
/// entry last; "Egal, irgendeins" at the foot takes an estimate instead.
class ProductSearchHubRecipeView extends ConsumerWidget {
  /// Creates the view.
  const new({
    required this.args,
    required this.search,
    required this.searchController,
    required this.searchFocusNode,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.isOffline,
    required this.onBackPressed,
    required this.onScanPressed,
    required this.onSearchChanged,
    required this.onClear,
    required this.onResultSelected,
    required this.onStockPicked,
    required this.onOwnEntryPressed,
    required this.onGuessed,
    super.key,
  });

  /// Route args with the recipe line.
  final ProductSearchHubRouteArgs args;

  /// The running search.
  final ProductSearchHubSearchCoordinator search;

  /// Search text controller.
  final TextEditingController searchController;

  /// Search focus node.
  final FocusNode searchFocusNode;

  /// Voice search service.
  final VoiceSearchService voiceSearchService;

  /// Voice search controller.
  final TextVoiceSearchController voiceSearchController;

  /// Whether the device is offline.
  final bool isOffline;

  /// Leaves the pick.
  final VoidCallback onBackPressed;

  /// Opens the scanner.
  final VoidCallback onScanPressed;

  /// Search text callback.
  final ValueChanged<String> onSearchChanged;

  /// Clears the search.
  final VoidCallback onClear;

  /// Picks a catalog food.
  final ValueChanged<OffProductSearchResult> onResultSelected;

  /// Picks Vorrat foods.
  final ValueChanged<List<InventoryItem>> onStockPicked;

  /// Opens the own entry of a food.
  final VoidCallback onOwnEntryPressed;

  /// Takes the food estimated by "Egal, irgendeins".
  final ValueChanged<RecipeFoodPick> onGuessed;

  /// Key of the row that opens the whole Vorrat.
  static const stockRowKey = Key('product_search_hub_recipe_stock_row');

  /// Key of the Vorrat food [itemId] among the search hits.
  static Key stockHitKey(String itemId) =>
      Key('product_search_hub_recipe_stock_hit_$itemId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final query = search.query.trim();
    final held = args.heldItemIds.join(',');
    final hits = args.takesFromStock && search.hasSearchQuery
        ? ref.watch(productSearchHubStockFoodsProvider(query, held)).value ??
              const <InventoryItem>[]
        : const <InventoryItem>[];
    final hasStock =
        args.takesFromStock &&
        (ref
                .watch(productSearchHubStockFoodsProvider('', held))
                .value
                ?.isNotEmpty ??
            false);
    return Scaffold(
      backgroundColor: colors.paper,
      bottomNavigationBar: RecipeGuessButton(args: args, onGuessed: onGuessed),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back works also while "Egal, irgendeins" estimates; leaving
            // drops the estimate.
            BackButton(onPressed: onBackPressed, color: colors.ink),
            Expanded(
              // While "Egal, irgendeins" estimates, nothing else takes a tap.
              child: AbsorbPointer(
                absorbing: ref.watch(
                  recipeFoodGuessControllerProvider.select(
                    (state) => state.isLoading,
                  ),
                ),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [
                          RecipeHead(args: args),
                          RecipeScanButton(onPressed: onScanPressed),
                          const RecipeOrPick(),
                          ProductSearchHubSearchBar(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            isSearching: search.isSearching,
                            voiceSearchService: voiceSearchService,
                            voiceSearchController: voiceSearchController,
                            onChanged: onSearchChanged,
                            onClear: onClear,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (hasStock)
                            RecipeFoodRow(
                              key: stockRowKey,
                              title: l10n.recipeFoodFromStock,
                              subtitle: l10n.recipeFoodFromStockLine,
                              icon: Icons.kitchen_outlined,
                              showsChevron: true,
                              onTap: () => _pickFromStock(context),
                            ),
                          for (final item in hits)
                            RecipeFoodRow(
                              key: stockHitKey(item.id),
                              title: item.name,
                              subtitle: recipeStockLine(l10n, item),
                              imageUrl: item.imageUrl,
                              onTap: () => onStockPicked([item]),
                            ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      sliver: RecipeCatalogHits(
                        search: search,
                        isOffline: isOffline,
                        onResultSelected: onResultSelected,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xs,
                        AppSpacing.xs,
                        AppSpacing.xl,
                        AppSpacing.xxxl,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: RecipeOwnEntryRow(onPressed: onOwnEntryPressed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromStock(BuildContext context) async {
    final item = await RecipeStockSheet.show(
      context,
      held: args.heldItemIds.join(','),
    );
    if (item != null && context.mounted) onStockPicked([item]);
  }
}
