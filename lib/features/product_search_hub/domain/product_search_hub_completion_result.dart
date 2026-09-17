import 'package:yamt/features/product_search_hub/domain/product_search_hub_saved_selection.dart';

/// Result of completing a hub product result.
class ProductSearchHubCompletionResult {
  const new _({required this.shouldCloseHub, this.selection});

  /// No user-visible completion action.
  const new none() : this._(shouldCloseHub: false);

  /// Close the hub after a direct save.
  const new closeHub({ProductSearchHubSavedSelection? selection})
    : this._(shouldCloseHub: true, selection: selection);

  /// Show saved item in the hub overlay.
  const new showOverlay(ProductSearchHubSavedSelection selection)
    : this._(shouldCloseHub: false, selection: selection);

  /// Whether hub should close after completion.
  final bool shouldCloseHub;

  /// Saved selection to show in overlay.
  final ProductSearchHubSavedSelection? selection;
}
