import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_actions.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_form_view.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_types.dart';

/// Full manual product editor for search, product details, and nutrition input.
class InventoryReceiptManualProductEditorPage extends ConsumerStatefulWidget {
  /// Creates a manual product editor page.
  const new({
    required this.config,
    required this.showEatImmediatelyOption,
    required this.initialAction,
    required this.closeCurrentEditorOnSave,
    this.quickEatConfig = InventoryManualAddQuickEatConfig.standard,
    this.showActionSelector = true,
    this.onSaved,
    this.autofocusSearch = false,
    this.initialStartVoiceSearch = false,
    this.initialRecentItem,
    this.initialInfoMessage,
    super.key,
  });

  /// Product search configuration.
  final InventoryReceiptManualProductConfig config;

  /// Quick-eat settings.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Whether the user can complete the flow as an immediate eat action.
  final bool showEatImmediatelyOption;

  /// Initially selected save action.
  final InventoryReceiptManualProductAction initialAction;

  /// Whether saving should pop only this editor route.
  final bool closeCurrentEditorOnSave;

  /// Whether the form should show the action selector.
  final bool showActionSelector;

  /// Called when the editor saves a product.
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  /// Whether the search field should autofocus.
  final bool autofocusSearch;

  /// Whether voice search should start when mounted.
  final bool initialStartVoiceSearch;

  /// Optional recent item to apply after mount.
  final InventoryItem? initialRecentItem;

  /// Optional message shown when the editor opens.
  final String? initialInfoMessage;

  @override
  ConsumerState<InventoryReceiptManualProductEditorPage> createState() =>
      _InventoryReceiptManualProductEditorPageState();
}

class _InventoryReceiptManualProductEditorPageState
    extends ConsumerState<InventoryReceiptManualProductEditorPage> {
  late final VoiceSearchService _voiceSearchService;
  final _voiceSearchController = TextVoiceSearchController();
  late final TextEditingController _searchController;
  ProviderSubscription<InventoryReceiptManualProductState>? _stateSubscription;
  bool _didBindProviderState = false;
  bool _didScheduleInitialRecentItem = false;
  late InventoryReceiptManualProductAction _selectedAction =
      widget.initialAction;
  late bool _showActionSelector = widget.showActionSelector;

  InventoryReceiptManualProductControllerProvider get _provider =>
      inventoryReceiptManualProductControllerProvider(widget.config);

  InventoryReceiptManualProductController get _controller =>
      ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    if (widget.quickEatConfig.quickEatOnly) {
      _selectedAction = InventoryReceiptManualProductAction.eatNow;
    }
    _searchController = TextEditingController();
    scheduleEditorInitialInfoMessage(
      message: widget.initialInfoMessage,
      isMounted: () => mounted,
      context: context,
      actionBuilder: () => buildEditorInitialInfoAction(
        context: context,
        canScanNutritionLabel: ref.read(_provider).canScanNutritionLabel,
        onScanNutritionLabel: _onScanNutritionLabel,
      ),
    );
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
      (previous, next) => _syncSearchController(next),
    );
    if (!_didScheduleInitialRecentItem) {
      _didScheduleInitialRecentItem = true;
      scheduleEditorInitialRecentItem(
        recentItem: widget.initialRecentItem,
        isMounted: () => mounted,
        onApplyRecentItem: _controller.applyRecentItem,
      );
    }
  }

  void _syncSearchController(InventoryReceiptManualProductState state) {
    replaceControllerText(
      _searchController,
      state.searchQuery,
      collapseSelectionToEnd: true,
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
    final state = ref.watch(_provider);
    final canSave = canSaveManualProduct(
      state: state,
      selectedAction: _selectedAction,
      config: widget.config,
    );

    return ManualProductSearchEditorFormView(
      state: state,
      controller: _controller,
      searchController: _searchController,
      voiceSearchController: _voiceSearchController,
      voiceSearchService: _voiceSearchService,
      quickEatConfig: widget.quickEatConfig,
      selectedAction: _selectedAction,
      showActionSelector: _showActionSelector,
      showEatImmediatelyOption: widget.showEatImmediatelyOption,
      autofocusSearch: widget.autofocusSearch,
      startVoiceSearchOnMount: widget.initialStartVoiceSearch,
      preview: buildEditorPreviewData(_controller),
      canSave: canSave,
      onSearchResultAction: _handleSearchResultAction,
      onScanBarcode: () => unawaited(_openBarcodeScanner()),
      onAiSearchTap: () => unawaited(_openAiSearchPage()),
      onCreateManualDraft: () => unawaited(_startManualProductDraft()),
      onScanNutritionLabel: state.canScanNutritionLabel
          ? _onScanNutritionLabel
          : null,
      onActionChanged: (action) => setState(() => _selectedAction = action),
      onCancel: _closePage,
      onSave: _onSave,
    );
  }

  void _onScanNutritionLabel() {
    unawaited(
      scanEditorNutritionLabel(
        controller: _controller,
        context: context,
        onShowSnackBar: _showSnackBar,
      ),
    );
  }

  void _onSave() {
    unawaited(
      executeEditorSave(
        ref: ref,
        config: widget.config,
        controller: _controller,
        selectedAction: _selectedAction,
        closeCurrentEditorOnSave: widget.closeCurrentEditorOnSave,
        onSaved: widget.onSaved,
        onClosePage: _closePage,
      ),
    );
  }

  void _handleSearchResultAction(
    OffProductSearchResult product,
    InventoryReceiptManualProductAction action,
  ) {
    unawaited(
      launchEditorSearchResultAction(
        context: context,
        quickEatConfig: widget.quickEatConfig,
        product: product,
        action: action,
        config: widget.config,
        controller: _controller,
        voiceSearchController: _voiceSearchController,
        autofocusSearch: widget.autofocusSearch,
        showEatImmediatelyOption: widget.showEatImmediatelyOption,
        onSaved: widget.onSaved,
        onClosePage: _closePage,
        onApplyAction: _apply,
      ),
    );
  }

  Future<void> _openBarcodeScanner() => launchEditorBarcodeScanner(
    context: context,
    quickEatConfig: widget.quickEatConfig,
    config: widget.config,
    controller: _controller,
    voiceSearchController: _voiceSearchController,
    showEatImmediatelyOption: widget.showEatImmediatelyOption,
    autofocusSearch: widget.autofocusSearch,
    onApplyAction: _apply,
    onShowSnackBar: _showSnackBar,
    onSaved: widget.onSaved,
    onClosePage: _closePage,
  );

  void _apply(InventoryReceiptManualProductAction action, VoidCallback apply) {
    if (mounted) {
      setState(() {
        _selectedAction = action;
        _showActionSelector = false;
      });
      apply();
    }
  }

  Future<void> _openAiSearchPage() => launchEditorAiSearchPage(
    context: context,
    quickEatConfig: widget.quickEatConfig,
    config: widget.config,
    voiceSearchController: _voiceSearchController,
    searchQuery: _searchController.text,
    showEatImmediatelyOption: widget.showEatImmediatelyOption,
    selectedAction: _selectedAction,
    closeCurrentEditorOnSave: widget.closeCurrentEditorOnSave,
    onSaved: widget.onSaved,
    onClosePage: _closePage,
  );

  Future<void> _startManualProductDraft() =>
      startManualProductDraftWithVoiceCleanup(
        voiceSearchController: _voiceSearchController,
        controller: _controller,
      );

  void _showSnackBar(String message) =>
      showEditorSnackBar(context, message, tone: AppSnackBarTone.error);

  void _closePage<T extends Object?>([T? result]) => closeEditorPage(
    context: context,
    voiceSearchController: _voiceSearchController,
    result: result,
  );
}
