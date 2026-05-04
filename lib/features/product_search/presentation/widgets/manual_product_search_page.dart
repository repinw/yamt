import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _manualProductRecentItemLimit = 6;
const _manualProductPageLogName = 'InventoryReceiptManualProductPage';

/// Initial action for the manual product launcher.
enum InventoryReceiptManualProductInitialIntent {
  /// Show the launcher without opening a child flow.
  launcher,

  /// Open the text search editor immediately.
  manualSearch,

  /// Open the AI suggestion page immediately.
  aiSuggestion,
}

/// Defines inventory receipt manual product page.
@Dependencies([inventoryItemRepository])
class InventoryReceiptManualProductPage extends StatelessWidget {
  /// The inventory receipt manual product page.
  const InventoryReceiptManualProductPage({
    required this.item,
    super.key,
    this.selectedProduct,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
    this.showEatImmediatelyOption = false,
    this.initialAction = InventoryReceiptManualProductAction.addToInventory,
    this.initialIntent = InventoryReceiptManualProductInitialIntent.launcher,
    this.onSaved,
  });

  /// The item.
  final InventoryItem item;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  /// The include store in search.
  final bool includeStoreInSearch;

  /// The include weight in search.
  final bool includeWeightInSearch;

  /// The show eat immediately option.
  final bool showEatImmediatelyOption;

  /// The initial action.
  final InventoryReceiptManualProductAction initialAction;

  /// The initial launcher intent.
  final InventoryReceiptManualProductInitialIntent initialIntent;

  /// Documented member.
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  Widget build(BuildContext context) {
    final config = InventoryReceiptManualProductConfig(
      item: item,
      selectedProduct: selectedProduct,
      includeStoreInSearch: includeStoreInSearch,
      includeWeightInSearch: includeWeightInSearch,
    );

    if (_shouldOpenEditorImmediately(
      item: item,
      selectedProduct: selectedProduct,
    )) {
      return _InventoryReceiptManualProductEditorPage(
        config: config,
        showEatImmediatelyOption: showEatImmediatelyOption,
        initialAction: initialAction,
        closeCurrentEditorOnSave: false,
        onSaved: onSaved,
      );
    }

    return _InventoryReceiptManualProductLauncherPage(
      config: config,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialIntent: initialIntent,
      onSaved: onSaved,
    );
  }
}

/// Defines inventory receipt manual product result.
class InventoryReceiptManualProductResult {
  /// The inventory receipt manual product result.
  const InventoryReceiptManualProductResult({
    required this.item,
    required this.action,
    this.selectedProduct,
    this.selectedGlobalFoodItemId,
    this.requiresGlobalPersistence = true,
    this.globalPackageWeight,
    this.skipMissingBarcodePrompt = false,
    this.eatRequest,
  });

  /// The item.
  final InventoryItem item;

  /// The action.
  final InventoryReceiptManualProductAction action;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  /// The selected global food item id.
  final String? selectedGlobalFoodItemId;

  /// The requires global persistence.
  final bool requiresGlobalPersistence;

  /// The package weight to persist on the global product.
  final String? globalPackageWeight;

  /// Whether missing barcode prompt should be skipped.
  final bool skipMissingBarcodePrompt;

  /// Eat request to complete directly after saving.
  final InventoryItemEatRequest? eatRequest;
}

bool _shouldOpenEditorImmediately({
  required InventoryItem item,
  required OffProductSearchResult? selectedProduct,
}) {
  return selectedProduct != null ||
      item.normalizedBarcode != null ||
      item.nutrition != null;
}

@Dependencies([inventoryItemRepository])
class _InventoryReceiptManualProductLauncherPage
    extends ConsumerStatefulWidget {
  const _InventoryReceiptManualProductLauncherPage({
    required this.config,
    required this.showEatImmediatelyOption,
    required this.initialIntent,
    this.onSaved,
  });

  final InventoryReceiptManualProductConfig config;
  final bool showEatImmediatelyOption;
  final InventoryReceiptManualProductInitialIntent initialIntent;
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  ConsumerState<_InventoryReceiptManualProductLauncherPage> createState() =>
      _InventoryReceiptManualProductLauncherPageState();
}

class _InventoryReceiptManualProductLauncherPageState
    extends ConsumerState<_InventoryReceiptManualProductLauncherPage> {
  late final TextEditingController _searchController;
  List<InventoryItem> _recentItems = const <InventoryItem>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: buildManualProductInitialSearchQuery(widget.config) ?? '',
    );
    unawaited(_loadRecentItems());
    if (widget.initialIntent !=
        InventoryReceiptManualProductInitialIntent.launcher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        switch (widget.initialIntent) {
          case InventoryReceiptManualProductInitialIntent.manualSearch:
            unawaited(_openSearchEditor());
          case InventoryReceiptManualProductInitialIntent.aiSuggestion:
            unawaited(_openAiSearchPage());
          case InventoryReceiptManualProductInitialIntent.launcher:
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: InventoryReceiptManualProductLauncherContent(
        title: l10n.inventoryManualAddSearchDialogTitle,
        searchController: _searchController,
        recentItems: _recentItems,
        onClose: _closePage,
        onAiSearchTap: () {
          unawaited(_openAiSearchPage());
        },
        onSearchTap: () {
          unawaited(_openSearchEditor());
        },
        onVoiceSearchTap: () {
          unawaited(_openVoiceSearchEditor());
        },
        onRecentItemSelected: (item) {
          unawaited(_openRecentItemEditor(item));
        },
        onRecentItemStoreSelected: widget.showEatImmediatelyOption
            ? _handleRecentItemStoreSelected
            : null,
        onRecentItemEatSelected: widget.showEatImmediatelyOption
            ? _handleRecentItemEatSelected
            : null,
        showRecentItemActions: widget.showEatImmediatelyOption,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
      ),
    );
  }

  Future<void> _loadRecentItems() async {
    try {
      final items = await ref.read(inventoryItemRepositoryProvider).readAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _recentItems = _buildRecentItems(items);
      });
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load recent manual product items.',
        name: _manualProductPageLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _openSearchEditor() async {
    await _openEditor(autofocusSearch: true);
  }

  Future<void> _openVoiceSearchEditor() async {
    await _openEditor(autofocusSearch: true, initialStartVoiceSearch: true);
  }

  Future<void> _openAiSearchPage() async {
    final result = await Navigator.of(context)
        .push<ManualProductAiSearchResult>(
          _NoAnimationMaterialPageRoute<ManualProductAiSearchResult>(
            fullscreenDialog: true,
            builder: (routeContext) {
              return ManualProductAiSearchPage(
                item: widget.config.item,
                initialPrompt: _searchController.text,
                showEatImmediatelyOption: widget.showEatImmediatelyOption,
              );
            },
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    await _completeSelectedResult(
      InventoryReceiptManualProductResult(
        item: result.item,
        action: result.action,
        globalPackageWeight: result.globalPackageWeight,
        skipMissingBarcodePrompt: true,
        eatRequest: result.eatRequest,
      ),
    );
  }

  Future<void> _openRecentItemEditor(InventoryItem item) async {
    await _openEditor(initialRecentItem: item);
  }

  void _handleRecentItemStoreSelected(InventoryItem item) {
    unawaited(
      _handleRecentItemActionSelected(
        item,
        InventoryReceiptManualProductAction.addToInventory,
      ),
    );
  }

  void _handleRecentItemEatSelected(InventoryItem item) {
    unawaited(
      _handleRecentItemActionSelected(
        item,
        InventoryReceiptManualProductAction.eatNow,
      ),
    );
  }

  Future<void> _handleRecentItemActionSelected(
    InventoryItem item,
    InventoryReceiptManualProductAction action,
  ) async {
    final directResult = action == InventoryReceiptManualProductAction.eatNow
        ? _directResultForRecentItem(item)
        : null;
    if (directResult != null) {
      await _completeSelectedResult(directResult);
      return;
    }

    await _openEditor(
      initialRecentItem: item,
      initialAction: action,
      showActionSelector: false,
      initialInfoMessage: action == InventoryReceiptManualProductAction.eatNow
          ? AppLocalizations.of(
              context,
            )!.inventoryManualAddEatNowRequiresNutrition
          : null,
    );
  }

  Future<void> _openEditor({
    InventoryItem? itemOverride,
    OffProductSearchResult? selectedProduct,
    InventoryItem? initialRecentItem,
    bool autofocusSearch = false,
    bool initialStartVoiceSearch = false,
    String? initialInfoMessage,
    InventoryReceiptManualProductAction initialAction =
        InventoryReceiptManualProductAction.addToInventory,
    bool showActionSelector = true,
  }) async {
    final config = InventoryReceiptManualProductConfig(
      item: itemOverride ?? widget.config.item,
      selectedProduct: selectedProduct,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final result = await Navigator.of(context)
        .push<InventoryReceiptManualProductResult>(
          _NoAnimationMaterialPageRoute<InventoryReceiptManualProductResult>(
            fullscreenDialog: true,
            builder: (routeContext) {
              return _InventoryReceiptManualProductEditorPage(
                config: config,
                showEatImmediatelyOption: widget.showEatImmediatelyOption,
                initialAction: initialAction,
                closeCurrentEditorOnSave: !autofocusSearch,
                showActionSelector: showActionSelector,
                onSaved: widget.onSaved,
                autofocusSearch: autofocusSearch,
                initialStartVoiceSearch: initialStartVoiceSearch,
                initialRecentItem: initialRecentItem,
                initialInfoMessage: initialInfoMessage,
              );
            },
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _openBarcodeScanner() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryManualAddScanBarcodeAction,
            showActionButtons: widget.showEatImmediatelyOption,
            onProductSelected: (candidate, scannedBarcode, action) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.selected(
                  candidate: candidate,
                  scannedBarcode: scannedBarcode,
                  action: action,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case _ManualBarcodeScanResultKind.selected:
        final candidate = result.candidate;
        if (candidate == null) {
          return;
        }
        final action = _manualProductActionFromBarcodeAction(result.action);
        final selectedProduct = candidate.externalProduct;
        if (selectedProduct != null) {
          final directResult = _directResultForSelectedProduct(
            product: selectedProduct,
            action: action,
          );
          if (directResult != null) {
            await _completeSelectedResult(directResult);
            return;
          }
          await _openEditor(
            selectedProduct: selectedProduct,
            initialAction: action,
            showActionSelector: false,
            initialInfoMessage:
                action == InventoryReceiptManualProductAction.eatNow
                ? l10n.inventoryManualAddEatNowRequiresNutrition
                : null,
          );
          return;
        }

        final globalFoodItem = candidate.globalFoodItem;
        if (globalFoodItem == null) {
          return;
        }
        final selectedItem = _inventoryItemFromBarcodeCandidate(
          baseItem: widget.config.item,
          globalFoodItem: globalFoodItem,
          barcode: result.scannedBarcode ?? candidate.barcode,
        );
        final directResult = _directResultForInventoryItem(
          item: selectedItem,
          action: action,
          selectedGlobalFoodItemId: candidate.globalFoodItemId,
          globalPackageWeight: candidate.packageWeight,
        );
        if (directResult != null) {
          await _completeSelectedResult(directResult);
          return;
        }
        await _openEditor(
          itemOverride: selectedItem,
          initialRecentItem: selectedItem,
          initialAction: action,
          showActionSelector: false,
          initialInfoMessage:
              action == InventoryReceiptManualProductAction.eatNow
              ? l10n.inventoryManualAddEatNowRequiresNutrition
              : null,
        );
      case _ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        await _openEditor(
          itemOverride: widget.config.item.copyWith(barcode: scannedBarcode),
          initialInfoMessage: l10n.inventoryManualAddNotFound,
        );
    }
  }

  InventoryReceiptManualProductResult? _directResultForSelectedProduct({
    required OffProductSearchResult product,
    required InventoryReceiptManualProductAction action,
  }) {
    if (action != InventoryReceiptManualProductAction.eatNow) {
      return null;
    }
    final config = InventoryReceiptManualProductConfig(
      item: widget.config.item,
      selectedProduct: product,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final controller = ref.read(
      inventoryReceiptManualProductControllerProvider(config).notifier,
    );
    final payload = controller.buildDirectSearchResultPayload(
      product: product,
      action: action,
    );
    if (payload == null) {
      return null;
    }
    return InventoryReceiptManualProductResult(
      item: payload.item,
      action: action,
      selectedProduct: payload.selectedProduct,
      selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
      requiresGlobalPersistence: payload.requiresGlobalPersistence,
      globalPackageWeight: payload.globalPackageWeight,
    );
  }

  InventoryReceiptManualProductResult? _directResultForInventoryItem({
    required InventoryItem item,
    required InventoryReceiptManualProductAction action,
    required String? selectedGlobalFoodItemId,
    required String? globalPackageWeight,
  }) {
    if (action != InventoryReceiptManualProductAction.eatNow ||
        item.nutrition?.hasAnyNutritionValue != true) {
      return null;
    }
    return InventoryReceiptManualProductResult(
      item: item,
      action: action,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId,
      requiresGlobalPersistence: false,
      globalPackageWeight: globalPackageWeight,
    );
  }

  InventoryReceiptManualProductResult? _directResultForRecentItem(
    InventoryItem item,
  ) {
    return _directResultForInventoryItem(
      item: item,
      action: InventoryReceiptManualProductAction.eatNow,
      selectedGlobalFoodItemId: _recentItemGlobalFoodItemId(item),
      globalPackageWeight: item.weight,
    );
  }

  Future<void> _completeSelectedResult(
    InventoryReceiptManualProductResult result,
  ) async {
    if (!mounted) {
      return;
    }
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  String? _recentItemGlobalFoodItemId(InventoryItem item) {
    final globalFoodItemId = item.globalFoodItemId.trim();
    if (globalFoodItemId.isEmpty ||
        isPendingGlobalFoodItemId(globalFoodItemId)) {
      return null;
    }
    return globalFoodItemId;
  }
}

class _InventoryReceiptManualProductEditorPage extends ConsumerStatefulWidget {
  const _InventoryReceiptManualProductEditorPage({
    required this.config,
    required this.showEatImmediatelyOption,
    required this.initialAction,
    required this.closeCurrentEditorOnSave,
    this.showActionSelector = true,
    this.onSaved,
    this.autofocusSearch = false,
    this.initialStartVoiceSearch = false,
    this.initialRecentItem,
    this.initialInfoMessage,
  });

  final InventoryReceiptManualProductConfig config;
  final bool showEatImmediatelyOption;
  final InventoryReceiptManualProductAction initialAction;
  final bool closeCurrentEditorOnSave;
  final bool showActionSelector;
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;
  final bool autofocusSearch;
  final bool initialStartVoiceSearch;
  final InventoryItem? initialRecentItem;
  final String? initialInfoMessage;

  @override
  ConsumerState<_InventoryReceiptManualProductEditorPage> createState() =>
      _InventoryReceiptManualProductEditorPageState();
}

class _NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _NoAnimationMaterialPageRoute({
    required super.builder,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

enum _ManualBarcodeScanResultKind { selected, notFound }

class _ManualBarcodeScanResult {
  const _ManualBarcodeScanResult._({
    required this.kind,
    this.action,
    this.candidate,
    this.scannedBarcode,
  });

  const _ManualBarcodeScanResult.selected({
    required InventoryBarcodeLookupCandidate candidate,
    required String scannedBarcode,
    required InventoryBarcodeCandidateAction action,
  }) : this._(
         kind: _ManualBarcodeScanResultKind.selected,
         action: action,
         candidate: candidate,
         scannedBarcode: scannedBarcode,
       );

  const _ManualBarcodeScanResult.notFound({required String scannedBarcode})
    : this._(
        kind: _ManualBarcodeScanResultKind.notFound,
        scannedBarcode: scannedBarcode,
      );

  final _ManualBarcodeScanResultKind kind;
  final InventoryBarcodeCandidateAction? action;
  final InventoryBarcodeLookupCandidate? candidate;
  final String? scannedBarcode;
}

InventoryReceiptManualProductAction _manualProductActionFromBarcodeAction(
  InventoryBarcodeCandidateAction? action,
) {
  return action == InventoryBarcodeCandidateAction.eatNow
      ? InventoryReceiptManualProductAction.eatNow
      : InventoryReceiptManualProductAction.addToInventory;
}

class _InventoryReceiptManualProductEditorPageState
    extends ConsumerState<_InventoryReceiptManualProductEditorPage> {
  late final VoiceSearchService _voiceSearchService;
  final _voiceSearchController = TextVoiceSearchController();
  late final TextEditingController _searchController;
  ProviderSubscription<InventoryReceiptManualProductState>? _stateSubscription;
  bool _didBindProviderState = false;
  bool _didScheduleInitialRecentItem = false;
  late InventoryReceiptManualProductAction _selectedAction =
      widget.initialAction;
  late bool _showActionSelector = widget.showActionSelector;

  InventoryReceiptManualProductControllerProvider get _provider {
    return inventoryReceiptManualProductControllerProvider(widget.config);
  }

  InventoryReceiptManualProductController get _controller {
    return ref.read(_provider.notifier);
  }

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchController = TextEditingController();
    final initialInfoMessage = widget.initialInfoMessage;
    if (initialInfoMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showSnackBar(initialInfoMessage);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindProviderState) {
      return;
    }

    _didBindProviderState = true;
    _syncSearchController(ref.read(_provider));
    _stateSubscription = ref.listenManual<InventoryReceiptManualProductState>(
      _provider,
      (previous, next) {
        _syncSearchController(next);
      },
    );
    final initialRecentItem = widget.initialRecentItem;
    if (!_didScheduleInitialRecentItem && initialRecentItem != null) {
      _didScheduleInitialRecentItem = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _controller.applyRecentItem(initialRecentItem);
      });
    }
  }

  void _syncSearchController(InventoryReceiptManualProductState state) {
    _replaceControllerText(
      _searchController,
      state.searchQuery,
      collapseSelectionToEnd: true,
    );
  }

  void _replaceControllerText(
    TextEditingController controller,
    String nextText, {
    bool collapseSelectionToEnd = false,
  }) {
    if (controller.text == nextText) {
      return;
    }

    final selection = collapseSelectionToEnd
        ? TextSelection.collapsed(offset: nextText.length)
        : _clampSelection(controller.selection, nextText.length);

    controller.value = TextEditingValue(
      text: nextText,
      selection: selection,
    );
  }

  TextSelection _clampSelection(TextSelection selection, int textLength) {
    final baseOffset = selection.baseOffset.clamp(0, textLength);
    final extentOffset = selection.extentOffset.clamp(0, textLength);
    return TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  @override
  void dispose() {
    _voiceSearchController.dispose();
    _stateSubscription?.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);
    final preview = _buildPreviewData();
    final canSave = _canSave(state);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: InventoryReceiptManualProductForm(
        title: l10n.inventoryManualAddSearchDialogTitle,
        preview: preview,
        searchController: _searchController,
        isSearching: state.isSearching,
        canSave: canSave,
        isRunningNutritionOcr: state.isRunningNutritionOcr,
        autofocusSearch: widget.autofocusSearch,
        showDetails: state.showDetails,
        searchResults: state.searchResults,
        recentItems: const <InventoryItem>[],
        nameText: state.nameText,
        brandText: state.brandText,
        weightAmount: state.weightAmount,
        selectedWeightUnit: state.selectedWeightUnit,
        kcalText: state.kcalText,
        saturatedFatText: state.saturatedFatText,
        polyunsaturatedFatText: state.polyunsaturatedFatText,
        showPolyunsaturatedFatField: state.showPolyunsaturatedFatField,
        fatText: state.fatText,
        carbsText: state.carbsText,
        sugarText: state.sugarText,
        fiberText: state.fiberText,
        showFiberField: state.showFiberField,
        proteinText: state.proteinText,
        saltText: state.saltText,
        canAddOptionalNutrition: state.canAddOptionalNutrition,
        isAddingOptionalNutrition: state.isAddingOptionalNutrition,
        optionalNutritionValueText: state.optionalNutritionValueText,
        optionalNutritionUnit: state.optionalNutritionUnit,
        optionalNutritionType: state.resolvedOptionalNutritionType,
        availableOptionalNutritionTypes: state.availableOptionalNutritionTypes,
        errorText: _resolveErrorText(l10n, state.error),
        onAiSearchTap: () {
          unawaited(_openAiSearchPage());
        },
        showActionSelector:
            widget.showEatImmediatelyOption && _showActionSelector,
        selectedAction: _selectedAction,
        onSearchResultSelected: _handleSearchResultSelected,
        onSearchResultStoreSelected: widget.showEatImmediatelyOption
            ? _handleSearchResultStoreSelected
            : null,
        onSearchResultEatSelected: widget.showEatImmediatelyOption
            ? _handleSearchResultEatSelected
            : null,
        onRecentItemSelected: _controller.applyRecentItem,
        onSearchChanged: _controller.updateSearchQuery,
        voiceSearchService: _voiceSearchService,
        voiceSearchController: _voiceSearchController,
        startVoiceSearchOnMount: widget.initialStartVoiceSearch,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
        onNameChanged: _controller.updateNameText,
        onBrandChanged: _controller.updateBrandText,
        onWeightAmountChanged: _controller.updateWeightAmount,
        onWeightUnitChanged: _controller.updateWeightUnit,
        onKcalChanged: _controller.updateKcalText,
        onFatChanged: _controller.updateFatText,
        onSaturatedFatChanged: _controller.updateSaturatedFatText,
        onCarbsChanged: _controller.updateCarbsText,
        onSugarChanged: _controller.updateSugarText,
        onProteinChanged: _controller.updateProteinText,
        onSaltChanged: _controller.updateSaltText,
        onPolyunsaturatedFatChanged: _controller.updatePolyunsaturatedFatText,
        onFiberChanged: _controller.updateFiberText,
        onScanNutritionLabel: state.canScanNutritionLabel
            ? () {
                unawaited(_scanNutritionLabel());
              }
            : null,
        onStartAddingOptionalNutrition:
            _controller.startAddingOptionalNutrition,
        onOptionalNutritionValueChanged:
            _controller.updateOptionalNutritionValueText,
        onOptionalNutritionUnitChanged: _controller.updateOptionalNutritionUnit,
        onOptionalNutritionTypeChanged: _controller.updateOptionalNutritionType,
        onApplyOptionalNutrition: _controller.applyOptionalNutrition,
        onCancelOptionalNutrition: _controller.cancelAddingOptionalNutrition,
        onActionChanged: (action) {
          setState(() {
            _selectedAction = action;
          });
        },
        onCancel: _closePage,
        onSave: () {
          unawaited(_save());
        },
      ),
    );
  }

  InventoryReceiptManualProductPreviewData? _buildPreviewData() {
    final preview = _controller.buildPreviewData();
    if (preview == null) {
      return null;
    }
    return InventoryReceiptManualProductPreviewData(
      imageUrl: preview.imageUrl,
      name: preview.name,
      brand: preview.brand,
      weight: preview.weight,
    );
  }

  void _handleSearchResultSelected(OffProductSearchResult product) {
    unawaited(
      _handleSearchResultActionSelected(
        product,
        InventoryReceiptManualProductAction.addToInventory,
      ),
    );
  }

  void _handleSearchResultStoreSelected(OffProductSearchResult product) {
    unawaited(
      _handleSearchResultActionSelected(
        product,
        InventoryReceiptManualProductAction.addToInventory,
      ),
    );
  }

  void _handleSearchResultEatSelected(OffProductSearchResult product) {
    unawaited(
      _handleSearchResultActionSelected(
        product,
        InventoryReceiptManualProductAction.eatNow,
      ),
    );
  }

  Future<void> _handleSearchResultActionSelected(
    OffProductSearchResult product,
    InventoryReceiptManualProductAction action,
  ) async {
    final eatNowRequiresNutritionMessage = AppLocalizations.of(
      context,
    )!.inventoryManualAddEatNowRequiresNutrition;
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (widget.autofocusSearch &&
        action == InventoryReceiptManualProductAction.eatNow) {
      final didStartDirectEat = _startDirectEatFlowFromSearchResult(product);
      if (didStartDirectEat) {
        return;
      }
    }
    if (widget.autofocusSearch) {
      await _openSelectedProductEditor(
        product,
        action: action,
        showActionSelector: false,
        initialInfoMessage: action == InventoryReceiptManualProductAction.eatNow
            ? eatNowRequiresNutritionMessage
            : null,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAction = action;
      _showActionSelector = false;
    });
    _controller.applySearchResult(product);
  }

  bool _startDirectEatFlowFromSearchResult(OffProductSearchResult product) {
    final payload = _controller.buildDirectSearchResultPayload(
      product: product,
      action: InventoryReceiptManualProductAction.eatNow,
    );
    if (payload == null) {
      return false;
    }

    _closePage(
      InventoryReceiptManualProductResult(
        item: payload.item,
        action: InventoryReceiptManualProductAction.eatNow,
        selectedProduct: payload.selectedProduct,
        selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
        requiresGlobalPersistence: payload.requiresGlobalPersistence,
        globalPackageWeight: payload.globalPackageWeight,
      ),
    );
    return true;
  }

  bool _startDirectEatFlowFromInventoryItem(
    InventoryItem item, {
    required String? selectedGlobalFoodItemId,
    required String? globalPackageWeight,
  }) {
    if (item.nutrition?.hasAnyNutritionValue != true) {
      return false;
    }

    _closePage(
      InventoryReceiptManualProductResult(
        item: item,
        action: InventoryReceiptManualProductAction.eatNow,
        selectedGlobalFoodItemId: selectedGlobalFoodItemId,
        requiresGlobalPersistence: false,
        globalPackageWeight: globalPackageWeight,
      ),
    );
    return true;
  }

  Future<void> _openSelectedProductEditor(
    OffProductSearchResult product, {
    required InventoryReceiptManualProductAction action,
    required bool showActionSelector,
    String? initialInfoMessage,
  }) async {
    final config = InventoryReceiptManualProductConfig(
      item: widget.config.item,
      selectedProduct: product,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final result = await Navigator.of(context)
        .push<InventoryReceiptManualProductResult>(
          _NoAnimationMaterialPageRoute<InventoryReceiptManualProductResult>(
            fullscreenDialog: true,
            builder: (routeContext) {
              return _InventoryReceiptManualProductEditorPage(
                config: config,
                showEatImmediatelyOption: widget.showEatImmediatelyOption,
                initialAction: action,
                closeCurrentEditorOnSave: true,
                showActionSelector: showActionSelector,
                onSaved: widget.onSaved,
                initialInfoMessage: initialInfoMessage,
              );
            },
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _save() async {
    final state = ref.read(_provider);
    if (state.isRunningNutritionOcr || !_canSave(state)) {
      return;
    }
    final payload = _controller.buildSavePayload(action: _selectedAction);
    if (payload == null) {
      return;
    }

    final result = InventoryReceiptManualProductResult(
      item: payload.item,
      action: _selectedAction,
      selectedProduct: payload.selectedProduct,
      selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
      requiresGlobalPersistence: payload.requiresGlobalPersistence,
      globalPackageWeight: payload.globalPackageWeight,
    );
    if (widget.closeCurrentEditorOnSave) {
      _closePage(result);
      return;
    }
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _openBarcodeScanner() async {
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryManualAddScanBarcodeAction,
            showActionButtons: widget.showEatImmediatelyOption,
            onProductSelected: (candidate, scannedBarcode, action) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.selected(
                  candidate: candidate,
                  scannedBarcode: scannedBarcode,
                  action: action,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case _ManualBarcodeScanResultKind.selected:
        final candidate = result.candidate;
        if (candidate == null) {
          return;
        }
        final action = _manualProductActionFromBarcodeAction(result.action);
        final selectedProduct = candidate.externalProduct;
        if (selectedProduct != null &&
            widget.autofocusSearch &&
            action == InventoryReceiptManualProductAction.eatNow &&
            _startDirectEatFlowFromSearchResult(selectedProduct)) {
          return;
        }
        if (selectedProduct != null && widget.autofocusSearch) {
          await _openSelectedProductEditor(
            selectedProduct,
            action: action,
            showActionSelector: false,
            initialInfoMessage:
                action == InventoryReceiptManualProductAction.eatNow
                ? AppLocalizations.of(
                    context,
                  )!.inventoryManualAddEatNowRequiresNutrition
                : null,
          );
          return;
        }
        if (selectedProduct != null) {
          if (mounted) {
            setState(() {
              _selectedAction = action;
              _showActionSelector = false;
            });
          }
          _controller.applyScannedProduct(selectedProduct);
          return;
        }

        final globalFoodItem = candidate.globalFoodItem;
        if (globalFoodItem == null) {
          return;
        }
        final selectedItem = _inventoryItemFromBarcodeCandidate(
          baseItem: widget.config.item,
          globalFoodItem: globalFoodItem,
          barcode: result.scannedBarcode ?? candidate.barcode,
        );
        if (widget.autofocusSearch &&
            action == InventoryReceiptManualProductAction.eatNow &&
            _startDirectEatFlowFromInventoryItem(
              selectedItem,
              selectedGlobalFoodItemId: candidate.globalFoodItemId,
              globalPackageWeight: candidate.packageWeight,
            )) {
          return;
        }
        _controller.applyRecentItem(selectedItem);
        if (mounted) {
          setState(() {
            _selectedAction = action;
            _showActionSelector = false;
          });
        }
      case _ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        _controller.applyScannedBarcodeOnly(scannedBarcode);
        _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddNotFound);
    }
  }

  Future<void> _openAiSearchPage() async {
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }

    final result = await Navigator.of(context)
        .push<ManualProductAiSearchResult>(
          _NoAnimationMaterialPageRoute<ManualProductAiSearchResult>(
            fullscreenDialog: true,
            builder: (routeContext) {
              return ManualProductAiSearchPage(
                item: widget.config.item,
                initialPrompt: _searchController.text,
                showEatImmediatelyOption: widget.showEatImmediatelyOption,
                initialAction: _selectedAction,
              );
            },
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    final wrappedResult = InventoryReceiptManualProductResult(
      item: result.item,
      action: result.action,
      globalPackageWeight: result.globalPackageWeight,
      skipMissingBarcodePrompt: true,
      eatRequest: result.eatRequest,
    );
    if (widget.closeCurrentEditorOnSave) {
      _closePage(wrappedResult);
      return;
    }
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(wrappedResult);
      return;
    }
    _closePage(wrappedResult);
  }

  Future<void> _scanNutritionLabel() async {
    final outcome = await _controller.scanNutritionLabel();
    if (!mounted) {
      return;
    }
    if (outcome == InventoryReceiptManualProductNutritionScanOutcome.failed) {
      _showSnackBar(AppLocalizations.of(context)!.caloriesOcrFailed);
    }
  }

  bool _canEatNow(InventoryReceiptManualProductState state) {
    if (state.hasNutritionInput) {
      return true;
    }
    if (state.selectedProduct?.nutrition?.hasAnyNutritionValue == true) {
      return true;
    }
    if (widget.config.selectedProduct?.nutrition?.hasAnyNutritionValue ==
        true) {
      return true;
    }
    return widget.config.item.nutrition?.hasAnyNutritionValue == true;
  }

  bool _canSave(InventoryReceiptManualProductState state) {
    if (!state.hasBarcode && !state.hasNutritionInput) {
      return false;
    }
    if (_selectedAction == InventoryReceiptManualProductAction.eatNow) {
      return _canEatNow(state);
    }
    return state.hasPackageWeightInput;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    unawaited(_voiceSearchController.cancelVoiceSearch());
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  String? _resolveErrorText(
    AppLocalizations l10n,
    InventoryReceiptManualProductError? error,
  ) {
    return switch (error) {
      null => null,
      InventoryReceiptManualProductError.requiredProductOrNutrition =>
        l10n.inventoryReceiptReviewManualDataRequired,
      InventoryReceiptManualProductError.requiredPackageWeight =>
        '${l10n.inventoryManualAddPackageSizeLabel}: '
            '${l10n.caloriesRequiredField}',
    };
  }
}

InventoryItem _inventoryItemFromBarcodeCandidate({
  required InventoryItem baseItem,
  required GlobalFoodItem globalFoodItem,
  required String barcode,
}) {
  final normalizedBarcode = normalizeBarcode(barcode);
  final weight = globalFoodItem.packageWeight ?? baseItem.weight;
  return baseItem
      .copyWith(
        globalFoodItemId: globalFoodItem.id,
        name: globalFoodItem.name,
        brand: globalFoodItem.brand,
        category: globalFoodItem.category,
        barcode: normalizedBarcode.isEmpty ? barcode : normalizedBarcode,
        imageUrl: globalFoodItem.imageUrl,
        weight: weight,
        foodFingerprint: globalFoodItem.resolvedFoodFingerprint,
        servingSize: globalFoodItem.servingSize,
        servingQuantity: globalFoodItem.servingQuantity,
        servingQuantityUnit: globalFoodItem.servingQuantityUnit,
        nutrition: globalFoodItem.nutrition,
      )
      .withDerivedAmount(
        weight: weight,
        quantity: baseItem.quantity,
        fallbackUnit: baseItem.amountUnit,
      );
}

List<InventoryItem> _buildRecentItems(List<InventoryItem> items) {
  final sortedItems =
      items
          .where((item) => item.canBeSavedToInventory)
          .where((item) => item.name.trim().isNotEmpty)
          .where((item) => item.isManuallyAdded)
          .toList(growable: false)
        ..sort((left, right) => right.entryDate.compareTo(left.entryDate));

  final recentItems = <InventoryItem>[];
  final seenKeys = <String>{};
  for (final item in sortedItems) {
    final key = _recentItemKey(item);
    if (!seenKeys.add(key)) {
      continue;
    }
    recentItems.add(item);
    if (recentItems.length >= _manualProductRecentItemLimit) {
      break;
    }
  }
  return recentItems;
}

String _recentItemKey(InventoryItem item) {
  final globalFoodItemId = item.globalFoodItemId.trim();
  if (globalFoodItemId.isNotEmpty &&
      !isPendingGlobalFoodItemId(globalFoodItemId)) {
    return 'global:$globalFoodItemId';
  }

  final barcode = item.normalizedBarcode;
  if (barcode != null && barcode.isNotEmpty) {
    return 'barcode:$barcode';
  }

  final normalizedName = item.name.trim().toLowerCase();
  final normalizedBrand = (item.brand ?? '').trim().toLowerCase();
  final normalizedWeight = (item.weight ?? '').trim().toLowerCase();
  return 'name:$normalizedName'
      '|brand:$normalizedBrand'
      '|weight:$normalizedWeight';
}
