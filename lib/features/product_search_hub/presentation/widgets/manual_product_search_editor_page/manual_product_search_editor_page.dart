import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
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
    'manual_product_search_page_route.dart';

/// Full manual product editor for product details and nutrition input.
class InventoryReceiptManualProductEditorPage extends ConsumerStatefulWidget {
  /// Creates a manual product editor page.
  const new({
    required this.config,
    required this.showEatImmediatelyOption,
    required this.initialAction,
    this.quickEatConfig = InventoryManualAddQuickEatConfig.standard,
    this.showActionSelector = true,
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

  /// Whether the form should show the action selector.
  final bool showActionSelector;

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
    if (widget.quickEatConfig.quickEatOnly) {
      _selectedAction = InventoryReceiptManualProductAction.eatNow;
    }
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
    if (!_didScheduleInitialRecentItem) {
      _didScheduleInitialRecentItem = true;
      scheduleEditorInitialRecentItem(
        recentItem: widget.initialRecentItem,
        isMounted: () => mounted,
        onApplyRecentItem: _controller.applyRecentItem,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final canSave = canSaveManualProduct(
      state: state,
      selectedAction: _selectedAction,
    );

    return ManualProductSearchEditorFormView(
      state: state,
      controller: _controller,
      quickEatConfig: widget.quickEatConfig,
      selectedAction: _selectedAction,
      showActionSelector: _showActionSelector,
      showEatImmediatelyOption: widget.showEatImmediatelyOption,
      preview: buildEditorPreviewData(_controller),
      canSave: canSave,
      onScanBarcode: () => unawaited(_openBarcodeScanner()),
      onScanNutritionLabel: state.canScanNutritionLabel
          ? _onScanNutritionLabel
          : null,
      onNoBarcodeChanged: (value) =>
          _controller.updateHasNoBarcode(value: value),
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
        onClosePage: _closePage,
      ),
    );
  }

  Future<void> _openBarcodeScanner() => launchEditorBarcodeScanner(
    context: context,
    quickEatConfig: widget.quickEatConfig,
    config: widget.config,
    controller: _controller,
    showEatImmediatelyOption: widget.showEatImmediatelyOption,
    onApplyAction: _apply,
    onShowSnackBar: _showSnackBar,
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

  void _showSnackBar(String message) =>
      showEditorSnackBar(context, message, tone: AppSnackBarTone.error);

  void _closePage<T extends Object?>([T? result]) =>
      popManualProductSearchPage(context, result);
}
