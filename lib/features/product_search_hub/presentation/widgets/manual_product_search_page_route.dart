import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';

part 'manual_product_search_page_route.g.dart';

/// In-memory payload store for internal product-search child routes.
@Riverpod(keepAlive: true)
ManualProductSearchRoutePayloadStore manualProductSearchRoutePayloadStore(
  Ref ref,
) {
  final store = ManualProductSearchRoutePayloadStore();
  ref.onDispose(store.clear);
  return store;
}

/// Builds a product-search child route page from URL state.
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
Widget buildManualProductSearchChild(ManualProductSearchRouteArgs args) {
  return ProviderScope(
    overrides: [
      inventoryManualAddQuickEatConfigProvider.overrideWithValue(
        args.quickEatConfig,
      ),
    ],
    child: switch (args.flow) {
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
    },
  );
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
      ? AppRoutes.homeProductSearchHub
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
