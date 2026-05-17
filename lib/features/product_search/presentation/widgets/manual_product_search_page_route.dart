import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page/manual_product_search_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';

part 'manual_product_search_page_route.g.dart';

const _flowParam = 'flow';
const _payloadParam = 'payload';

/// In-memory payload store for internal product-search child routes.
@Riverpod(keepAlive: true)
ManualProductSearchRoutePayloadStore manualProductSearchRoutePayloadStore(
  Ref ref,
) {
  final store = ManualProductSearchRoutePayloadStore();
  ref.onDispose(store.clear);
  return store;
}

/// Handles a save result emitted by a product-search route.
typedef ManualProductSearchRouteSaveHandler =
    Future<void> Function(InventoryReceiptManualProductResult result);

/// Stores transient route payloads behind short URL-safe ids.
class ManualProductSearchRoutePayloadStore {
  /// Creates a route payload store.
  ManualProductSearchRoutePayloadStore();

  final _payloads = <String, ManualProductSearchRouteArgs>{};
  var _nextPayloadId = 0;

  /// Stores args and returns the generated payload id.
  String put(ManualProductSearchRouteArgs args) {
    final payloadId = 'manual_product_search_${_nextPayloadId++}';
    _payloads[payloadId] = args;
    return payloadId;
  }

  /// Reads args for a payload id when it belongs to the requested flow.
  ManualProductSearchRouteArgs? read({
    required ManualProductSearchChildFlow flow,
    required String? payloadId,
  }) {
    if (payloadId == null || payloadId.isEmpty) {
      return null;
    }
    final args = _payloads[payloadId];
    if (args == null || args.flow != flow) {
      return null;
    }
    return args;
  }

  /// Removes a payload after its route has completed.
  void remove(String? payloadId) {
    if (payloadId == null) {
      return;
    }
    _payloads.remove(payloadId);
  }

  /// Clears all payloads when the owning provider scope is disposed.
  void clear() {
    _payloads.clear();
  }
}

/// Product-search child route types.
enum ManualProductSearchChildFlow {
  /// Full manual product page.
  manualProduct('manual-product'),

  /// Manual editor page.
  editor('editor'),

  /// AI search page.
  aiSearch('ai-search')
  ;

  const ManualProductSearchChildFlow(this.pathSegment);

  /// Stable path segment.
  final String pathSegment;

  /// Resolves a stable path segment to a child flow.
  static ManualProductSearchChildFlow? fromPathSegment(String? value) {
    for (final flow in values) {
      if (flow.pathSegment == value) {
        return flow;
      }
    }
    return null;
  }
}

/// Serializable route arguments for a product-search child flow.
class ManualProductSearchRouteArgs {
  const ManualProductSearchRouteArgs._({
    required this.flow,
    required this.item,
    required this.includeStoreInSearch,
    required this.includeWeightInSearch,
    required this.showEatImmediatelyOption,
    required this.initialAction,
    required this.closeCurrentEditorOnSave,
    required this.showActionSelector,
    required this.autofocusSearch,
    required this.initialStartVoiceSearch,
    this.selectedProduct,
    this.initialRecentItem,
    this.initialPrompt,
    this.initialInfoMessage,
    this.onSaved,
  });

  /// Creates manual product page route args.
  factory ManualProductSearchRouteArgs.manualProduct({
    required InventoryItem item,
    bool includeStoreInSearch = true,
    bool includeWeightInSearch = true,
    bool showEatImmediatelyOption = false,
    InventoryReceiptManualProductAction initialAction =
        InventoryReceiptManualProductAction.addToInventory,
  }) {
    return ManualProductSearchRouteArgs._(
      flow: ManualProductSearchChildFlow.manualProduct,
      item: item,
      includeStoreInSearch: includeStoreInSearch,
      includeWeightInSearch: includeWeightInSearch,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialAction: initialAction,
      closeCurrentEditorOnSave: true,
      showActionSelector: true,
      autofocusSearch: false,
      initialStartVoiceSearch: false,
    );
  }

  /// Creates manual editor route args.
  factory ManualProductSearchRouteArgs.editor({
    required InventoryReceiptManualProductConfig config,
    required bool showEatImmediatelyOption,
    required InventoryReceiptManualProductAction initialAction,
    required bool closeCurrentEditorOnSave,
    required bool showActionSelector,
    bool autofocusSearch = false,
    bool initialStartVoiceSearch = false,
    InventoryItem? initialRecentItem,
    String? initialInfoMessage,
    ManualProductSearchRouteSaveHandler? onSaved,
  }) {
    return ManualProductSearchRouteArgs._(
      flow: ManualProductSearchChildFlow.editor,
      item: config.item,
      selectedProduct: config.selectedProduct,
      includeStoreInSearch: config.includeStoreInSearch,
      includeWeightInSearch: config.includeWeightInSearch,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialAction: initialAction,
      closeCurrentEditorOnSave: closeCurrentEditorOnSave,
      showActionSelector: showActionSelector,
      autofocusSearch: autofocusSearch,
      initialStartVoiceSearch: initialStartVoiceSearch,
      initialRecentItem: initialRecentItem,
      initialInfoMessage: initialInfoMessage,
      onSaved: onSaved,
    );
  }

  /// Creates AI search route args.
  factory ManualProductSearchRouteArgs.aiSearch({
    required InventoryItem item,
    required String initialPrompt,
    required bool showEatImmediatelyOption,
    required InventoryReceiptManualProductAction initialAction,
  }) {
    return ManualProductSearchRouteArgs._(
      flow: ManualProductSearchChildFlow.aiSearch,
      item: item,
      includeStoreInSearch: true,
      includeWeightInSearch: true,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialAction: initialAction,
      closeCurrentEditorOnSave: true,
      showActionSelector: true,
      autofocusSearch: false,
      initialStartVoiceSearch: false,
      initialPrompt: initialPrompt,
    );
  }

  /// Parses route args from a go_router state.
  factory ManualProductSearchRouteArgs.fromState(
    GoRouterState state,
    ManualProductSearchRoutePayloadStore payloadStore,
  ) {
    final args = ManualProductSearchRouteArgs.tryParse(state, payloadStore);
    if (args == null) {
      throw FormatException(
        'Invalid product-search child route: ${state.uri}',
      );
    }
    return args;
  }

  /// Parses route args, returning null when required URL data is missing.
  static ManualProductSearchRouteArgs? tryParse(
    GoRouterState state,
    ManualProductSearchRoutePayloadStore payloadStore,
  ) {
    final flow = ManualProductSearchChildFlow.fromPathSegment(
      state.pathParameters[_flowParam],
    );
    if (flow == null) {
      return null;
    }
    return payloadStore.read(
      flow: flow,
      payloadId: state.uri.queryParameters[_payloadParam],
    );
  }

  /// Child flow type.
  final ManualProductSearchChildFlow flow;

  /// Base inventory item.
  final InventoryItem item;

  /// Optional selected OFF product.
  final OffProductSearchResult? selectedProduct;

  /// Optional recent item to apply to editor state.
  final InventoryItem? initialRecentItem;

  /// Initial AI prompt.
  final String? initialPrompt;

  /// Whether store is included in manual search.
  final bool includeStoreInSearch;

  /// Whether weight is included in manual search.
  final bool includeWeightInSearch;

  /// Whether eat-now is available.
  final bool showEatImmediatelyOption;

  /// Initial save action.
  final InventoryReceiptManualProductAction initialAction;

  /// Whether editor save should close only the current route.
  final bool closeCurrentEditorOnSave;

  /// Whether editor action selector is shown.
  final bool showActionSelector;

  /// Whether editor search field should autofocus.
  final bool autofocusSearch;

  /// Whether editor voice search should start immediately.
  final bool initialStartVoiceSearch;

  /// Optional editor info message.
  final String? initialInfoMessage;

  /// Optional route-local save handler.
  final ManualProductSearchRouteSaveHandler? onSaved;

  /// Concrete URL location for this route payload.
  String locationForPayload(String payloadId) {
    final query = <String, String>{_payloadParam: payloadId};
    return Uri(
      path: AppRoutes.productSearchChildFlowPath(flow.pathSegment),
      queryParameters: query,
    ).toString();
  }
}

/// Builds a product-search child route page from URL state.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
Page<Object?> buildManualProductSearchRoutePage(
  BuildContext context,
  GoRouterState state,
) {
  final payloadStore = ProviderScope.containerOf(context, listen: false).read(
    manualProductSearchRoutePayloadStoreProvider,
  );
  final args = ManualProductSearchRouteArgs.tryParse(state, payloadStore);
  if (args == null) {
    return NoTransitionPage<Object?>(
      key: state.pageKey,
      child: const SizedBox.shrink(),
    );
  }
  return NoTransitionPage<Object?>(
    key: state.pageKey,
    child: buildManualProductSearchChild(args),
  );
}

/// Builds the product-search child widget from parsed route args.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
Widget buildManualProductSearchChild(ManualProductSearchRouteArgs args) {
  return switch (args.flow) {
    ManualProductSearchChildFlow.manualProduct =>
      InventoryReceiptManualProductPage(
        item: args.item,
        selectedProduct: args.selectedProduct,
        includeStoreInSearch: args.includeStoreInSearch,
        includeWeightInSearch: args.includeWeightInSearch,
        showEatImmediatelyOption: args.showEatImmediatelyOption,
        initialAction: args.initialAction,
      ),
    ManualProductSearchChildFlow.editor =>
      InventoryReceiptManualProductEditorPage(
        config: InventoryReceiptManualProductConfig(
          item: args.item,
          selectedProduct: args.selectedProduct,
          includeStoreInSearch: args.includeStoreInSearch,
          includeWeightInSearch: args.includeWeightInSearch,
        ),
        showEatImmediatelyOption: args.showEatImmediatelyOption,
        initialAction: args.initialAction,
        closeCurrentEditorOnSave: args.closeCurrentEditorOnSave,
        showActionSelector: args.showActionSelector,
        autofocusSearch: args.autofocusSearch,
        initialStartVoiceSearch: args.initialStartVoiceSearch,
        initialRecentItem: args.initialRecentItem,
        initialInfoMessage: args.initialInfoMessage,
        onSaved: args.onSaved,
      ),
    ManualProductSearchChildFlow.aiSearch => ManualProductAiSearchPage(
      item: args.item,
      initialPrompt: args.initialPrompt ?? '',
      showEatImmediatelyOption: args.showEatImmediatelyOption,
      initialAction: args.initialAction,
    ),
  };
}

/// Redirect target for invalid product-search child URLs.
String? redirectInvalidManualProductSearchRoute(
  BuildContext context,
  GoRouterState state,
) {
  final payloadStore = ProviderScope.containerOf(context, listen: false).read(
    manualProductSearchRoutePayloadStoreProvider,
  );
  return ManualProductSearchRouteArgs.tryParse(state, payloadStore) == null
      ? AppRoutes.homeInventoryManualAdd
      : null;
}

/// Pushes a nested manual product flow page without route animation.
Future<T?> pushManualProductSearchPage<T extends Object?>({
  required BuildContext context,
  required ManualProductSearchRouteArgs args,
}) async {
  final payloadStore = ProviderScope.containerOf(context, listen: false).read(
    manualProductSearchRoutePayloadStoreProvider,
  );
  final payloadId = payloadStore.put(args);
  try {
    return await GoRouter.of(context).push<T>(
      args.locationForPayload(payloadId),
    );
  } finally {
    payloadStore.remove(payloadId);
  }
}

/// Pops a manual product flow page through go_router.
void popManualProductSearchPage<T extends Object?>(
  BuildContext context, [
  T? result,
]) {
  context.pop<T>(result);
}
