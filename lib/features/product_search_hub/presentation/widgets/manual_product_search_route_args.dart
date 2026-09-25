import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';

/// Query/path parameter name for child route flow type.
const manualProductSearchFlowParam = 'flow';

/// Query parameter name for child route payload id.
const manualProductSearchPayloadParam = 'payload';

/// Stores transient route payloads behind short URL-safe ids.
class ManualProductSearchRoutePayloadStore {
  /// Creates a route payload store.
  new();

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
  /// Manual editor page.
  editor('editor'),

  /// AI search page.
  aiSearch('ai-search');

  new(this.pathSegment);

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
  const new _({
    required this.flow,
    required this.item,
    required this.showEatImmediatelyOption,
    required this.initialAction,
    required this.showActionSelector,
    required this.quickEatConfig,
    this.selectedProduct,
    this.initialRecentItem,
    this.initialPrompt,
    this.initialInfoMessage,
  });

  /// Creates manual editor route args.
  factory editor({
    required InventoryReceiptManualProductConfig config,
    required bool showEatImmediatelyOption,
    required InventoryReceiptManualProductAction initialAction,
    required bool showActionSelector,
    InventoryManualAddQuickEatConfig quickEatConfig =
        InventoryManualAddQuickEatConfig.standard,
    InventoryItem? initialRecentItem,
    String? initialInfoMessage,
  }) {
    return ManualProductSearchRouteArgs._(
      flow: ManualProductSearchChildFlow.editor,
      item: config.item,
      selectedProduct: config.selectedProduct,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialAction: initialAction,
      showActionSelector: showActionSelector,
      quickEatConfig: quickEatConfig,
      initialRecentItem: initialRecentItem,
      initialInfoMessage: initialInfoMessage,
    );
  }

  /// Creates AI search route args.
  factory aiSearch({
    required InventoryItem item,
    required String initialPrompt,
    required bool showEatImmediatelyOption,
    required InventoryReceiptManualProductAction initialAction,
    InventoryManualAddQuickEatConfig quickEatConfig =
        InventoryManualAddQuickEatConfig.standard,
  }) {
    return ManualProductSearchRouteArgs._(
      flow: ManualProductSearchChildFlow.aiSearch,
      item: item,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialAction: initialAction,
      showActionSelector: true,
      quickEatConfig: quickEatConfig,
      initialPrompt: initialPrompt,
    );
  }

  /// Parses route args from a go_router state.
  factory fromState(
    GoRouterState state,
    ManualProductSearchRoutePayloadStore payloadStore,
  ) {
    final args = ManualProductSearchRouteArgs.tryParse(state, payloadStore);
    if (args == null) {
      throw FormatException('Invalid product-search child route: ${state.uri}');
    }
    return args;
  }

  /// Parses route args, returning null when required URL data is missing.
  static ManualProductSearchRouteArgs? tryParse(
    GoRouterState state,
    ManualProductSearchRoutePayloadStore payloadStore,
  ) {
    final flow = ManualProductSearchChildFlow.fromPathSegment(
      state.pathParameters[manualProductSearchFlowParam],
    );
    if (flow == null) {
      return null;
    }
    return payloadStore.read(
      flow: flow,
      payloadId: state.uri.queryParameters[manualProductSearchPayloadParam],
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

  /// Whether eat-now is available.
  final bool showEatImmediatelyOption;

  /// Initial save action.
  final InventoryReceiptManualProductAction initialAction;

  /// Whether editor action selector is shown.
  final bool showActionSelector;

  /// Quick-eat config scoped to product-search child pages.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Optional editor info message.
  final String? initialInfoMessage;

  /// Concrete URL location for this route payload.
  String locationForPayload(String payloadId) {
    final query = <String, String>{manualProductSearchPayloadParam: payloadId};
    return Uri(
      path: AppRoutes.productSearchChildFlowPath(flow.pathSegment),
      queryParameters: query,
    ).toString();
  }
}
