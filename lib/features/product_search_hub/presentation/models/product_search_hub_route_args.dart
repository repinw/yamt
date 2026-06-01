import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product search hub launch mode.
enum ProductSearchHubMode {
  /// Add selected products to inventory.
  inventory,

  /// Eat selected products from diary flows.
  diary,

  /// Return edited product result to the caller without persistence.
  selection,
}

/// Optional action to start immediately after the hub opens.
enum ProductSearchHubInitialIntent {
  /// Show the hub normally.
  launcher,

  /// Open text search.
  search,

  /// Open AI product creation.
  ai,

  /// Open barcode scanner.
  barcode,
}

/// Route args for product search hub.
class ProductSearchHubRouteArgs {
  /// Creates route args.
  const ProductSearchHubRouteArgs({
    this.mode = ProductSearchHubMode.inventory,
    this.initialIntent = ProductSearchHubInitialIntent.launcher,
    this.item,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
    this.preselectedMealType,
    this.preselectedLoggedAt,
    this.startVoiceSearchOnMount = false,
  });

  /// Inventory add route args.
  const ProductSearchHubRouteArgs.inventory({
    ProductSearchHubInitialIntent initialIntent =
        ProductSearchHubInitialIntent.launcher,
    InventoryItem? item,
    bool includeStoreInSearch = true,
    bool includeWeightInSearch = true,
    bool startVoiceSearchOnMount = false,
  }) : this(
         mode: ProductSearchHubMode.inventory,
         initialIntent: initialIntent,
         item: item,
         includeStoreInSearch: includeStoreInSearch,
         includeWeightInSearch: includeWeightInSearch,
         startVoiceSearchOnMount: startVoiceSearchOnMount,
       );

  /// Diary eat route args.
  const ProductSearchHubRouteArgs.diary({
    ProductSearchHubInitialIntent initialIntent =
        ProductSearchHubInitialIntent.launcher,
    InventoryItem? item,
    bool includeStoreInSearch = true,
    bool includeWeightInSearch = true,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
    bool startVoiceSearchOnMount = false,
  }) : this(
         mode: ProductSearchHubMode.diary,
         initialIntent: initialIntent,
         item: item,
         includeStoreInSearch: includeStoreInSearch,
         includeWeightInSearch: includeWeightInSearch,
         preselectedMealType: preselectedMealType,
         preselectedLoggedAt: preselectedLoggedAt,
         startVoiceSearchOnMount: startVoiceSearchOnMount,
       );

  /// Selection route args.
  const ProductSearchHubRouteArgs.selection({
    required InventoryItem item,
    ProductSearchHubInitialIntent initialIntent =
        ProductSearchHubInitialIntent.launcher,
    bool includeStoreInSearch = true,
    bool includeWeightInSearch = true,
    bool startVoiceSearchOnMount = false,
  }) : this(
         mode: ProductSearchHubMode.selection,
         initialIntent: initialIntent,
         item: item,
         includeStoreInSearch: includeStoreInSearch,
         includeWeightInSearch: includeWeightInSearch,
         startVoiceSearchOnMount: startVoiceSearchOnMount,
       );

  /// Launch mode.
  final ProductSearchHubMode mode;

  /// Initial action.
  final ProductSearchHubInitialIntent initialIntent;

  /// Optional base item used when hub replaces old product-search routes.
  final InventoryItem? item;

  /// Whether store should be sent to product search.
  final bool includeStoreInSearch;

  /// Whether weight should be sent to product search.
  final bool includeWeightInSearch;

  /// Preselected diary meal type.
  final MealType? preselectedMealType;

  /// Preselected diary logged-at date.
  final DateTime? preselectedLoggedAt;

  /// Whether focused search should start voice search on mount.
  final bool startVoiceSearchOnMount;

  /// Whether diary source buttons should be shown.
  bool get showsDiarySourceActions => mode == ProductSearchHubMode.diary;

  /// Localized route title.
  String title(AppLocalizations l10n) {
    return switch (mode) {
      ProductSearchHubMode.inventory => l10n.productSearchHubInventoryTitle,
      ProductSearchHubMode.diary => l10n.productSearchHubDiaryTitle,
      ProductSearchHubMode.selection => l10n.productSearchHubTitle,
    };
  }

  /// Returns route args for a focused voice search launch.
  ProductSearchHubRouteArgs withVoiceSearchOnMount() {
    return ProductSearchHubRouteArgs(
      mode: mode,
      initialIntent: initialIntent,
      item: item,
      includeStoreInSearch: includeStoreInSearch,
      includeWeightInSearch: includeWeightInSearch,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
      startVoiceSearchOnMount: true,
    );
  }
}

/// Resolves route args from go_router extra.
ProductSearchHubRouteArgs resolveProductSearchHubRouteArgs(Object? extra) {
  if (extra is ProductSearchHubRouteArgs) {
    return extra;
  }
  if (extra is ProductSearchHubMode) {
    return ProductSearchHubRouteArgs(mode: extra);
  }
  return const ProductSearchHubRouteArgs.inventory();
}
