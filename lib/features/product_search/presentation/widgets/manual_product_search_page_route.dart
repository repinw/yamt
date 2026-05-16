import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/application/'
    'manual_product_recent_items_service.dart';
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

const _flowParam = 'flow';
const _itemParam = 'item';
const _selectedProductParam = 'selectedProduct';
const _initialRecentItemParam = 'initialRecentItem';
const _initialPromptParam = 'initialPrompt';
const _initialActionParam = 'initialAction';
const _includeStoreParam = 'includeStore';
const _includeWeightParam = 'includeWeight';
const _showEatParam = 'showEat';
const _closeCurrentEditorParam = 'closeCurrentEditor';
const _showActionSelectorParam = 'showActionSelector';
const _autofocusSearchParam = 'autofocusSearch';
const _initialVoiceSearchParam = 'initialVoiceSearch';
const _initialInfoMessageParam = 'initialInfoMessage';
const _onSavedHandlerParam = 'onSavedHandler';

final _saveHandlers = <String, ManualProductSearchRouteSaveHandler>{};
var _nextSaveHandlerId = 0;

/// Handles a save result emitted by a product-search route.
typedef ManualProductSearchRouteSaveHandler =
    Future<void> Function(InventoryReceiptManualProductResult result);

/// Registers a route-local save handler and returns its URL-safe id.
String registerManualProductSearchRouteSaveHandler(
  ManualProductSearchRouteSaveHandler handler,
) {
  final id = 'manual_product_search_save_${_nextSaveHandlerId++}';
  _saveHandlers[id] = handler;
  return id;
}

/// Removes a previously registered route save handler.
void unregisterManualProductSearchRouteSaveHandler(String? id) {
  if (id == null) {
    return;
  }
  _saveHandlers.remove(id);
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
    this.onSavedHandlerId,
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
    String? onSavedHandlerId,
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
      onSavedHandlerId: onSavedHandlerId,
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
  factory ManualProductSearchRouteArgs.fromState(GoRouterState state) {
    final args = ManualProductSearchRouteArgs.tryParse(state);
    if (args == null) {
      throw FormatException(
        'Invalid product-search child route: ${state.uri}',
      );
    }
    return args;
  }

  /// Parses route args, returning null when required URL data is missing.
  static ManualProductSearchRouteArgs? tryParse(GoRouterState state) {
    final flow = ManualProductSearchChildFlow.fromPathSegment(
      state.pathParameters[_flowParam],
    );
    if (flow == null) {
      return null;
    }
    final query = state.uri.queryParameters;
    final item = _decodeInventoryItem(query[_itemParam]);
    if (item == null) {
      return null;
    }
    final initialAction = _readEnum(
      query[_initialActionParam],
      InventoryReceiptManualProductAction.values,
    );
    if (initialAction == null) {
      return null;
    }

    return ManualProductSearchRouteArgs._(
      flow: flow,
      item: item,
      selectedProduct: _decodeProduct(query[_selectedProductParam]),
      initialRecentItem: _decodeInventoryItem(query[_initialRecentItemParam]),
      initialPrompt: query[_initialPromptParam],
      includeStoreInSearch: _readBool(query[_includeStoreParam]),
      includeWeightInSearch: _readBool(query[_includeWeightParam]),
      showEatImmediatelyOption: _readBool(query[_showEatParam]),
      initialAction: initialAction,
      closeCurrentEditorOnSave: _readBool(query[_closeCurrentEditorParam]),
      showActionSelector: _readBool(query[_showActionSelectorParam]),
      autofocusSearch: _readBool(query[_autofocusSearchParam]),
      initialStartVoiceSearch: _readBool(query[_initialVoiceSearchParam]),
      initialInfoMessage: query[_initialInfoMessageParam],
      onSavedHandlerId: query[_onSavedHandlerParam],
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

  /// Optional id for an in-memory save handler.
  final String? onSavedHandlerId;

  /// Concrete URL location for this route.
  String get location {
    final query = <String, String>{
      _itemParam: _encodeJson(item.toJson()),
      _initialActionParam: initialAction.name,
      _includeStoreParam: _writeBool(includeStoreInSearch),
      _includeWeightParam: _writeBool(includeWeightInSearch),
      _showEatParam: _writeBool(showEatImmediatelyOption),
      _closeCurrentEditorParam: _writeBool(closeCurrentEditorOnSave),
      _showActionSelectorParam: _writeBool(showActionSelector),
      _autofocusSearchParam: _writeBool(autofocusSearch),
      _initialVoiceSearchParam: _writeBool(initialStartVoiceSearch),
    };
    final selectedProduct = this.selectedProduct;
    if (selectedProduct != null) {
      query[_selectedProductParam] = _encodeJson(
        _productToJson(selectedProduct),
      );
    }
    final initialRecentItem = this.initialRecentItem;
    if (initialRecentItem != null) {
      query[_initialRecentItemParam] = _encodeJson(initialRecentItem.toJson());
    }
    final initialPrompt = this.initialPrompt;
    if (initialPrompt != null) {
      query[_initialPromptParam] = initialPrompt;
    }
    final initialInfoMessage = this.initialInfoMessage;
    if (initialInfoMessage != null) {
      query[_initialInfoMessageParam] = initialInfoMessage;
    }
    final onSavedHandlerId = this.onSavedHandlerId;
    if (onSavedHandlerId != null) {
      query[_onSavedHandlerParam] = onSavedHandlerId;
    }
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
Page<Object?> buildManualProductSearchRoutePage(GoRouterState state) {
  final args = ManualProductSearchRouteArgs.tryParse(state);
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
  final onSaved = _saveHandlers[args.onSavedHandlerId];
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
        onSaved: onSaved,
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
String? redirectInvalidManualProductSearchRoute(GoRouterState state) {
  return ManualProductSearchRouteArgs.tryParse(state) == null
      ? AppRoutes.homeInventoryManualAdd
      : null;
}

/// Pushes a nested manual product flow page without route animation.
Future<T?> pushManualProductSearchPage<T extends Object?>({
  required BuildContext context,
  required ManualProductSearchRouteArgs args,
}) {
  return GoRouter.of(context).push<T>(args.location);
}

/// Pops a manual product flow page through go_router.
void popManualProductSearchPage<T extends Object?>(
  BuildContext context, [
  T? result,
]) {
  context.pop<T>(result);
}

String _encodeJson(Map<String, dynamic> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json)));
}

Map<String, dynamic>? _decodeJson(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  try {
    final decoded = utf8.decode(base64Url.decode(value));
    final json = jsonDecode(decoded);
    if (json is Map<String, dynamic>) {
      return json;
    }
  } on Object {
    return null;
  }
  return null;
}

InventoryItem? _decodeInventoryItem(String? value) {
  final json = _decodeJson(value);
  if (json == null) {
    return null;
  }
  try {
    return InventoryItem.fromJson(json);
  } on Object {
    return null;
  }
}

OffProductSearchResult? _decodeProduct(String? value) {
  final json = _decodeJson(value);
  if (json == null) {
    return null;
  }
  try {
    return OffProductSearchResult(
      code: _readString(json['code']),
      name: _readString(json['name']),
      score: _readDouble(json['score']) ?? 0,
      brand: _readOptionalString(json['brand']),
      imageUrl: _readOptionalString(json['image_url']),
      packageWeight: _readOptionalString(json['package_weight']),
      servingSize: _readOptionalString(json['serving_size']),
      servingQuantity: _readDouble(json['serving_quantity']),
      servingQuantityUnit: _readOptionalString(json['serving_quantity_unit']),
      nutrition: _readNutrition(json['nutrition']),
    );
  } on Object {
    return null;
  }
}

Map<String, dynamic> _productToJson(OffProductSearchResult product) {
  return <String, dynamic>{
    'code': product.code,
    'name': product.name,
    'score': product.score,
    'brand': product.brand,
    'image_url': product.imageUrl,
    'package_weight': product.packageWeight,
    'serving_size': product.servingSize,
    'serving_quantity': product.servingQuantity,
    'serving_quantity_unit': product.servingQuantityUnit,
    'nutrition': product.nutrition?.toJson(),
  };
}

GlobalFoodNutrition? _readNutrition(Object? value) {
  if (value is Map<String, dynamic>) {
    return GlobalFoodNutrition.fromJson(value);
  }
  return null;
}

T? _readEnum<T extends Enum>(String? value, List<T> values) {
  if (value == null) {
    return null;
  }
  for (final enumValue in values) {
    if (enumValue.name == value) {
      return enumValue;
    }
  }
  return null;
}

bool _readBool(String? value) {
  return value == '1' || value == 'true';
}

String _writeBool(bool value) {
  return value ? '1' : '0';
}

String _readString(Object? value) {
  return value is String ? value : '';
}

String? _readOptionalString(Object? value) {
  final string = _readString(value).trim();
  return string.isEmpty ? null : string;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
