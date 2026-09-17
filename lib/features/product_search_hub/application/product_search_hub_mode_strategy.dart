import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Strategy defining mode-specific presentation behavior for the Product
/// Search Hub.
abstract interface class ProductSearchHubModeStrategy {
  /// The hub mode this strategy represents.
  ProductSearchHubMode get mode;

  /// Localized title for the hub app bar.
  String title(AppLocalizations l10n);

  /// Whether diary actions (meal, recipe, etc.) are visible.
  bool get showsDiarySourceActions;

  /// Whether the hub is running in diary mode.
  bool get isDiary;

  /// Default action to preselect when opening the product editor.
  InventoryReceiptManualProductAction get initialManualProductAction;
}

/// Resolves the mode strategy for a given [ProductSearchHubMode].
ProductSearchHubModeStrategy productSearchHubModeStrategy(
  ProductSearchHubMode mode,
) {
  return switch (mode) {
    ProductSearchHubMode.inventory => const InventoryHubModeStrategy(),
    ProductSearchHubMode.diary => const DiaryHubModeStrategy(),
    ProductSearchHubMode.selection => const SelectionHubModeStrategy(),
  };
}

/// Strategy for inventory mode.
class InventoryHubModeStrategy implements ProductSearchHubModeStrategy {
  /// Creates an inventory hub mode strategy.
  const new();

  @override
  ProductSearchHubMode get mode => ProductSearchHubMode.inventory;

  @override
  String title(AppLocalizations l10n) => l10n.productSearchHubInventoryTitle;

  @override
  bool get showsDiarySourceActions => false;

  @override
  bool get isDiary => false;

  @override
  InventoryReceiptManualProductAction get initialManualProductAction =>
      InventoryReceiptManualProductAction.addToInventory;
}

/// Strategy for diary mode.
class DiaryHubModeStrategy implements ProductSearchHubModeStrategy {
  /// Creates a diary hub mode strategy.
  const new();

  @override
  ProductSearchHubMode get mode => ProductSearchHubMode.diary;

  @override
  String title(AppLocalizations l10n) => l10n.productSearchHubDiaryTitle;

  @override
  bool get showsDiarySourceActions => true;

  @override
  bool get isDiary => true;

  @override
  InventoryReceiptManualProductAction get initialManualProductAction =>
      InventoryReceiptManualProductAction.eatNow;
}

/// Strategy for selection mode.
class SelectionHubModeStrategy implements ProductSearchHubModeStrategy {
  /// Creates a selection hub mode strategy.
  const new();

  @override
  ProductSearchHubMode get mode => ProductSearchHubMode.selection;

  @override
  String title(AppLocalizations l10n) => l10n.productSearchHubTitle;

  @override
  bool get showsDiarySourceActions => false;

  @override
  bool get isDiary => false;

  @override
  InventoryReceiptManualProductAction get initialManualProductAction =>
      InventoryReceiptManualProductAction.addToInventory;
}
