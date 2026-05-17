import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_editor/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_remove_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_amount_input_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_progress.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_action_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_expand_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_main_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory item row.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  manualProductRecentItemsService,
])
class InventoryItemRow extends ConsumerStatefulWidget {
  /// The inventory item row.
  const InventoryItemRow({
    required this.expansionStorageKey,
    required this.item,
    required this.l10n,
    required this.isAlreadyInShoppingList,
    required this.onDeletePressed,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
    super.key,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onStartSelection,
    this.onSelectionToggle,
  });

  /// The expansion storage key.
  final String expansionStorageKey;

  /// The item.
  final InventoryItem item;

  /// The l10n.
  final AppLocalizations l10n;

  /// Whether already in shopping list.
  final bool isAlreadyInShoppingList;

  /// The on delete pressed.
  final Future<bool> Function(String itemId) onDeletePressed;

  /// The on eat pressed.
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatPressed;

  /// The on throw away pressed.
  final Future<InventoryItemDiscardResult?> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayPressed;

  /// Whether selection mode.
  final bool isSelectionMode;

  /// Whether selected.
  final bool isSelected;

  /// The on start selection.
  final VoidCallback? onStartSelection;

  /// The on selection toggle.
  final VoidCallback? onSelectionToggle;

  @override
  ConsumerState<InventoryItemRow> createState() => _InventoryItemRowState();
}

class _InventoryItemRowState extends ConsumerState<InventoryItemRow> {
  static const _removeUndoSnackBarDuration = Duration(seconds: 5);

  var _isExpanded = false;
  var _isWorking = false;
  var _isEditSheetOpen = false;
  var _didRestoreExpansionState = false;
  late final InventoryItemRowActionCoordinator _actionCoordinator;

  @override
  void initState() {
    super.initState();
    _actionCoordinator = InventoryItemRowActionCoordinator(
      isWorking: () => _isWorking,
      setWorking: _setWorking,
      isMounted: () => mounted,
      showSnackBar: _showActionSnackBar,
      defaultFailureMessage: widget.l10n.inventoryItemActionFailed,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestoreExpansionState) {
      return;
    }
    _didRestoreExpansionState = true;

    final restoredState = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: widget.expansionStorageKey);
    if (restoredState is bool) {
      _isExpanded = restoredState;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutData = _buildLayoutData(
      context,
      isAlreadyInShoppingList: widget.isAlreadyInShoppingList,
      isSelectionMode: widget.isSelectionMode,
    );
    final onPrimaryActionPressed = _buildPrimaryActionPressed(layoutData);
    final onQuickShoppingListActionPressed =
        _buildQuickShoppingListActionPressed(layoutData);

    return _InventoryItemRowCard(
      layoutData: layoutData,
      isExpanded: !widget.isSelectionMode && _isExpanded,
      isSelectionMode: widget.isSelectionMode,
      isSelected: widget.isSelected,
      removeLabel: widget.l10n.inventoryItemRemoveAction,
      editLabel: widget.l10n.inventoryReceiptReviewEditAction,
      swapCandidateLabel: widget.l10n.inventoryItemSwapCandidateAction,
      onToggleExpanded: widget.isSelectionMode
          ? (widget.onSelectionToggle ?? () {})
          : _toggleExpanded,
      onEditPressed: layoutData.isEditActionEnabled
          ? (_isWorking ? () {} : _onEditPressed)
          : null,
      onPrimaryActionPressed: onPrimaryActionPressed,
      onQuickShoppingListActionPressed: onQuickShoppingListActionPressed,
      onSwapCandidatePressed: _isWorking ? () {} : _onSwapCandidatePressed,
      onRemovePressed: layoutData.isRemoveActionEnabled
          ? _onRemovePressed
          : null,
      onStartSelection: widget.onStartSelection,
    );
  }

  VoidCallback? _buildPrimaryActionPressed(
    _InventoryItemRowLayoutData layoutData,
  ) {
    if (!layoutData.isPrimaryActionEnabled) {
      return null;
    }
    if (layoutData.isShoppingListPrimaryAction) {
      return _onAddToShoppingListPressed;
    }
    return _onEatPressed;
  }

  VoidCallback? _buildQuickShoppingListActionPressed(
    _InventoryItemRowLayoutData layoutData,
  ) {
    if (!layoutData.isQuickShoppingListActionEnabled) {
      return null;
    }
    return _onAddToShoppingListPressed;
  }

  _InventoryItemRowLayoutData _buildLayoutData(
    BuildContext context, {
    required bool isAlreadyInShoppingList,
    required bool isSelectionMode,
  }) {
    final item = widget.item;
    final hasAdjustableAmount = _buildInputConfig(item) != null;
    return _InventoryItemRowLayoutData.fromItem(
      context: context,
      item: item,
      l10n: widget.l10n,
      hasAdjustableAmount: hasAdjustableAmount,
      isWorking: _isWorking,
      isAlreadyInShoppingList: isAlreadyInShoppingList,
      isSelectionMode: isSelectionMode,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, _isExpanded, identifier: widget.expansionStorageKey);
  }

  void _setWorking(bool isWorking) {
    setState(() {
      _isWorking = isWorking;
    });
  }

  void _onEatPressed() {
    unawaited(_requestEatAmountAndRunAction(action: widget.onEatPressed));
  }

  void _onRemovePressed() {
    unawaited(_requestRemoveAndRunAction());
  }

  void _onEditPressed() {
    if (!widget.item.isFullyAvailable) {
      _showActionSnackBar(widget.l10n.inventoryItemEditRequiresFullItem);
      return;
    }
    unawaited(_runEditFlow());
  }

  void _onAddToShoppingListPressed() {
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    unawaited(
      _actionCoordinator.runAction(
        () => controller.buyAgainItem(widget.item),
        successMessage: widget.l10n.inventoryItemBuyAgainSucceeded,
        failureMessage: widget.l10n.inventoryItemActionFailed,
      ),
    );
  }

  void _onSwapCandidatePressed() {
    if (!widget.item.isFullyAvailable) {
      _showActionSnackBar(
        widget.l10n.inventoryItemSwapCandidateRequiresFullItem,
      );
      return;
    }
    unawaited(_runSwapCandidateFlow());
  }

  Future<void> _runSwapCandidateFlow() async {
    if (_isWorking) {
      return;
    }

    _setWorking(true);
    try {
      final request = await showInventoryItemCandidateSwapFlow(
        context: context,
        ref: ref,
        item: widget.item,
      );
      if (!mounted || request == null) {
        return;
      }

      final saved = await ref
          .read(inventoryItemsControllerProvider.notifier)
          .swapItemCandidate(
            itemId: widget.item.id,
            resolvedProduct: request.resolvedProduct,
            requiresGlobalPersistence: request.requiresGlobalPersistence,
            weight: request.weight,
          );
      if (!mounted || saved) {
        return;
      }

      _showActionSnackBar(widget.l10n.inventoryItemActionFailed);
    } finally {
      if (mounted) {
        _setWorking(false);
      }
    }
  }

  Future<void> _runEditFlow() async {
    if (_isWorking || _isEditSheetOpen) {
      return;
    }

    _isEditSheetOpen = true;
    try {
      final editedItem = await showModalBottomSheet<InventoryItem>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        builder: (sheetContext) {
          return InventoryReceiptItemEditorSheet(
            item: widget.item,
            title: widget.l10n.inventoryItemEditTitle,
            showDiscountFields: false,
            showReviewOnlyFields: false,
          );
        },
      );
      if (!mounted || editedItem == null || editedItem == widget.item) {
        return;
      }

      final controller = ref.read(inventoryItemsControllerProvider.notifier);
      await _actionCoordinator.runAction(
        () => controller.updateItem(editedItem),
        successMessage: widget.l10n.inventoryItemUpdatedMessage,
        failureMessage: widget.l10n.inventoryItemActionFailed,
      );
    } finally {
      _isEditSheetOpen = false;
    }
  }

  Future<void> _requestEatAmountAndRunAction({
    required Future<bool> Function(
      String itemId,
      InventoryItemEatRequest request,
    )
    action,
  }) async {
    final config = _buildInputConfig(widget.item);
    if (config == null) {
      return;
    }

    final result = await showInventoryItemEatSheet(
      context: context,
      item: widget.item,
      maxAmount: config.maxAmount,
      invalidAmountMessage: widget.l10n.inventoryReceiptReviewInvalidNumber,
    );
    if (!mounted || result == null) {
      return;
    }

    await _actionCoordinator.runAction(() => action(widget.item.id, result));
  }

  Future<void> _requestRemoveAndRunAction() async {
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final config = _buildInputConfig(widget.item);
    final removalChoice = await showInventoryItemRemoveDialog(
      context,
      itemName: widget.item.name,
      canReduceAmount: config != null,
    );
    if (!mounted || removalChoice == null) {
      return;
    }

    await _waitForDialogDismissal();
    if (!mounted) {
      return;
    }

    switch (removalChoice) {
      case InventoryItemRemovalChoice.discarded:
        if (config == null) {
          return;
        }
        await _handleDiscardChoice(controller: controller, config: config);
        return;
      case InventoryItemRemovalChoice.consumedElsewhere:
        if (config == null) {
          return;
        }
        await _handleConsumeElsewhereChoice(
          controller: controller,
          config: config,
        );
        return;
      case InventoryItemRemovalChoice.deleteCompletely:
        await _actionCoordinator.runAction(
          () => widget.onDeletePressed(widget.item.id),
        );
        return;
    }
  }

  Future<void> _handleDiscardChoice({
    required InventoryItemsController controller,
    required _ItemAmountInputConfig config,
  }) async {
    final discardReason = await showInventoryDiscardReasonDialog(
      context,
      itemName: widget.item.name,
    );
    if (!mounted || discardReason == null) {
      return;
    }
    await _waitForDialogDismissal();
    if (!mounted) {
      return;
    }

    final discardedAmount = await _promptForAmount(
      config: config,
      title: widget.l10n.inventoryItemRemoveDiscardAction,
      confirmLabel: widget.l10n.inventoryItemRemoveDiscardAction,
      quickFillLabel: widget.l10n.inventoryAmountDialogAllRemainingAction,
    );
    if (!mounted || discardedAmount == null) {
      return;
    }
    await _waitForDialogDismissal();
    if (!mounted) {
      return;
    }

    InventoryItemDiscardResult? discardResult;
    await _actionCoordinator.runAction(
      () async {
        discardResult = await widget.onThrowAwayPressed(
          widget.item.id,
          discardedAmount,
          discardReason,
        );
        return discardResult != null;
      },
    );
    if (!mounted || discardResult == null) {
      return;
    }

    _showUndoSnackBar(
      message: widget.l10n.inventoryItemRemovedMessage,
      onUndo: () => controller.undoThrowAwayItem(
        itemId: widget.item.id,
        amount: discardResult!.removedAmount,
        discardEventId: discardResult!.discardEventId,
      ),
    );
  }

  Future<void> _handleConsumeElsewhereChoice({
    required InventoryItemsController controller,
    required _ItemAmountInputConfig config,
  }) async {
    final consumedAmount = await _promptForAmount(
      config: config,
      title: widget.l10n.inventoryItemRemoveConsumeElsewhereAction,
      confirmLabel: widget.l10n.inventoryItemRemoveConsumeElsewhereAction,
      quickFillLabel: widget.l10n.inventoryAmountDialogAllRemainingAction,
    );
    if (!mounted || consumedAmount == null) {
      return;
    }
    await _waitForDialogDismissal();
    if (!mounted) {
      return;
    }

    InventoryItemReductionResult? consumptionResult;
    await _actionCoordinator.runAction(
      () async {
        consumptionResult = await controller.eatItemDetailed(
          widget.item.id,
          consumedAmount,
        );
        return consumptionResult != null;
      },
    );
    if (!mounted || consumptionResult == null) {
      return;
    }

    _showUndoSnackBar(
      message: widget.l10n.inventoryItemRemovedMessage,
      onUndo: () => controller.restoreConsumedItem(
        widget.item.id,
        consumptionResult!.removedAmount,
      ),
    );
  }

  Future<int?> _promptForAmount({
    required _ItemAmountInputConfig config,
    required String title,
    required String confirmLabel,
    String? quickFillLabel,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return InventoryItemAmountInputDialog(
          title: title,
          confirmLabel: confirmLabel,
          cancelLabel: widget.l10n.inventoryReceiptReviewCancelAction,
          fieldLabel: config.fieldLabel,
          invalidAmountMessage: widget.l10n.inventoryReceiptReviewInvalidNumber,
          maxAmount: config.maxAmount,
          quickFillLabel: quickFillLabel,
          suffixText: config.suffixText,
          amountUnit: config.amountUnit,
          amountScale: config.amountScale,
        );
      },
    );
  }

  Future<void> _waitForDialogDismissal() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  void _showActionSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showUndoSnackBar({
    required String message,
    required Future<bool> Function() onUndo,
  }) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _removeUndoSnackBarDuration,
          persist: false,
          content: Text(message),
          action: SnackBarAction(
            label: widget.l10n.commonUndoAction,
            onPressed: () {
              unawaited(_runUndoAction(onUndo));
            },
          ),
        ),
      );
  }

  Future<void> _runUndoAction(Future<bool> Function() onUndo) async {
    final restored = await onUndo();
    if (!mounted) {
      return;
    }
    if (restored) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }
    _showActionSnackBar(widget.l10n.inventoryItemActionFailed);
  }

  _ItemAmountInputConfig? _buildInputConfig(InventoryItem item) {
    if (item.usesAmountProgress) {
      final maxAmount = item.currentAmount > 0 ? item.currentAmount : 0;
      if (maxAmount < 1 || item.amountUnit == null) {
        return null;
      }
      return _ItemAmountInputConfig(
        maxAmount: maxAmount,
        fieldLabel: widget.l10n.inventoryReceiptReviewFieldWeight,
        suffixText: item.amountUnit!.localizedName(widget.l10n),
        amountUnit: item.amountUnit,
        amountScale: item.amountScale,
      );
    }

    final maxAmount = item.quantity > 0 ? item.quantity : 0;
    if (maxAmount < 1) {
      return null;
    }
    return _ItemAmountInputConfig(
      maxAmount: maxAmount,
      fieldLabel: widget.l10n.inventoryReceiptReviewFieldQuantity,
      suffixText: null,
      amountUnit: null,
      amountScale: 1,
    );
  }
}

class _ItemAmountInputConfig {
  const _ItemAmountInputConfig({
    required this.maxAmount,
    required this.fieldLabel,
    required this.suffixText,
    required this.amountUnit,
    required this.amountScale,
  });

  final int maxAmount;
  final String fieldLabel;
  final String? suffixText;
  final InventoryAmountUnit? amountUnit;
  final int amountScale;
}

class _InventoryItemRowLayoutData {
  const _InventoryItemRowLayoutData({
    required this.colorScheme,
    required this.snapshot,
    required this.viewData,
    required this.isPrimaryActionEnabled,
    required this.isShoppingListPrimaryAction,
    required this.isQuickShoppingListActionEnabled,
    required this.isEditActionEnabled,
    required this.isRemoveActionEnabled,
  });

  factory _InventoryItemRowLayoutData.fromItem({
    required BuildContext context,
    required InventoryItem item,
    required AppLocalizations l10n,
    required bool hasAdjustableAmount,
    required bool isWorking,
    required bool isAlreadyInShoppingList,
    required bool isSelectionMode,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isShoppingListPrimaryAction = item.isFullyConsumed;
    final eatActionColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final shoppingListActionColors =
        AppInventoryBuyAgainActionColors.fromColorScheme(colors);
    final progress = const InventoryItemProgressCalculator().fromItem(item);
    final brand = item.brand?.trim() ?? '';
    final hasBrand = brand.isNotEmpty;
    final canRunSecondaryActions = !isSelectionMode && !isWorking;
    final isEditActionEnabled = !isSelectionMode;
    final isRemoveActionEnabled = canRunSecondaryActions;
    final isPrimaryActionEnabled =
        canRunSecondaryActions &&
        (isShoppingListPrimaryAction
            ? !isAlreadyInShoppingList
            : hasAdjustableAmount);
    final isQuickShoppingListActionEnabled =
        canRunSecondaryActions && !isAlreadyInShoppingList;

    return _InventoryItemRowLayoutData(
      colorScheme: colors,
      snapshot: InventoryItemRowSnapshot.fromItem(item),
      viewData: InventoryItemRowViewData(
        rowBorderColor: AppInventoryEditorialSurfaces.ghostBorder(colors),
        expandedRowBorderColor: colors.primary.withValues(alpha: 0.2),
        nameTextStyle:
            (Theme.of(context).textTheme.titleMedium ?? const TextStyle())
                .copyWith(
                  color: item.isFullyConsumed
                      ? colors.onSurface.withValues(alpha: 0.5)
                      : colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
        hasBrand: hasBrand,
        brand: brand,
        remainingRatio: progress.remainingRatio,
        remainingLabel: progress.remainingLabel,
        segmentedByUnits: progress.segmentedByUnits,
        isShoppingListPrimaryAction: isShoppingListPrimaryAction,
        showPrimaryActionIconWithText: isShoppingListPrimaryAction,
        primaryActionLabel: isShoppingListPrimaryAction
            ? l10n.inventoryItemAddToListAction
            : l10n.inventoryItemEatAction,
        eatActionBackgroundColor: isShoppingListPrimaryAction
            ? shoppingListActionColors.backgroundColor
            : eatActionColors.backgroundColor,
        disabledActionBackgroundColor: AppInventoryEditorialSurfaces.section(
          colors,
        ),
        eatActionBorderColor: isShoppingListPrimaryAction
            ? shoppingListActionColors.borderColor
            : eatActionColors.borderColor,
        disabledActionBorderColor: AppInventoryEditorialSurfaces.ghostBorder(
          colors,
        ),
        primaryActionTooltip: isShoppingListPrimaryAction
            ? l10n.inventoryItemAddToShoppingListAction
            : l10n.inventoryItemEatAction,
        primaryActionIcon: isShoppingListPrimaryAction
            ? Icons.shopping_cart_outlined
            : Icons.restaurant_menu,
        eatActionIconColor: isShoppingListPrimaryAction
            ? shoppingListActionColors.iconColor
            : eatActionColors.iconColor,
        disabledActionIconColor: colors.onSurfaceVariant,
        showQuickShoppingListAction: !isShoppingListPrimaryAction,
        isQuickShoppingListActionEnabled: isQuickShoppingListActionEnabled,
        quickShoppingListActionTooltip:
            l10n.inventoryItemAddToShoppingListAction,
        quickShoppingListActionIcon: Icons.shopping_cart_outlined,
        quickShoppingListActionBackgroundColor:
            shoppingListActionColors.backgroundColor,
        quickShoppingListActionBorderColor:
            shoppingListActionColors.borderColor,
        quickShoppingListActionIconColor: shoppingListActionColors.iconColor,
        nutritionMetrics: _buildNutritionMetrics(l10n, item),
      ),
      isPrimaryActionEnabled: isPrimaryActionEnabled,
      isShoppingListPrimaryAction: isShoppingListPrimaryAction,
      isQuickShoppingListActionEnabled: isQuickShoppingListActionEnabled,
      isEditActionEnabled: isEditActionEnabled,
      isRemoveActionEnabled: isRemoveActionEnabled,
    );
  }

  final ColorScheme colorScheme;
  final InventoryItemRowSnapshot snapshot;
  final InventoryItemRowViewData viewData;
  final bool isPrimaryActionEnabled;
  final bool isShoppingListPrimaryAction;
  final bool isQuickShoppingListActionEnabled;
  final bool isEditActionEnabled;
  final bool isRemoveActionEnabled;
}

List<InventoryNutritionMetric> _buildNutritionMetrics(
  AppLocalizations l10n,
  InventoryItem item,
) {
  final nutrition = item.nutrition;
  if (nutrition == null || !nutrition.hasAnyNutritionValue) {
    return const <InventoryNutritionMetric>[];
  }

  return [
    if (nutrition.per100Kcal != null)
      InventoryNutritionMetric(
        label: l10n.inventoryNutritionCaloriesShortLabel,
        value: nutrition.per100Kcal!.round().toString(),
      ),
    if (nutrition.per100Carbs != null)
      InventoryNutritionMetric(
        label: l10n.inventoryNutritionCarbsShortLabel,
        value: '${formatInventoryNutritionValue(nutrition.per100Carbs!)}g',
      ),
    if (nutrition.per100Protein != null)
      InventoryNutritionMetric(
        label: l10n.caloriesProteinLabel,
        value: '${formatInventoryNutritionValue(nutrition.per100Protein!)}g',
      ),
    if (nutrition.per100Fat != null)
      InventoryNutritionMetric(
        label: l10n.caloriesFatLabel,
        value: '${formatInventoryNutritionValue(nutrition.per100Fat!)}g',
      ),
  ];
}

class _InventoryItemRowCard extends StatelessWidget {
  const _InventoryItemRowCard({
    required this.layoutData,
    required this.isExpanded,
    required this.isSelectionMode,
    required this.isSelected,
    required this.removeLabel,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.onToggleExpanded,
    required this.onEditPressed,
    required this.onPrimaryActionPressed,
    required this.onQuickShoppingListActionPressed,
    required this.onSwapCandidatePressed,
    required this.onRemovePressed,
    required this.onStartSelection,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final bool isSelectionMode;
  final bool isSelected;
  final String removeLabel;
  final String editLabel;
  final String swapCandidateLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onEditPressed;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback? onQuickShoppingListActionPressed;
  final VoidCallback onSwapCandidatePressed;
  final VoidCallback? onRemovePressed;

  final VoidCallback? onStartSelection;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppInventoryEditorial.cardRadius);
    final colors = layoutData.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(
          alpha: isExpanded ? 0.95 : 0.9,
        ),
        borderRadius: radius,
        border: Border.all(
          color: isExpanded
              ? layoutData.viewData.expandedRowBorderColor
              : layoutData.viewData.rowBorderColor,
        ),
        boxShadow: [
          if (isExpanded)
            AppInventoryEditorialSurfaces.ambientBoxShadow(
              colors,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: AppInkWell(
            onTap: onToggleExpanded,
            onLongPress: isSelectionMode ? null : onStartSelection,
            child: _InventoryItemRowBody(
              layoutData: layoutData,
              isExpanded: isExpanded,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              removeLabel: removeLabel,
              editLabel: editLabel,
              swapCandidateLabel: swapCandidateLabel,
              onToggleExpanded: onToggleExpanded,
              onEditPressed: onEditPressed,
              onPrimaryActionPressed: onPrimaryActionPressed,
              onQuickShoppingListActionPressed:
                  onQuickShoppingListActionPressed,
              onSwapCandidatePressed: onSwapCandidatePressed,
              onRemovePressed: onRemovePressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryItemRowBody extends StatelessWidget {
  const _InventoryItemRowBody({
    required this.layoutData,
    required this.isExpanded,
    required this.isSelectionMode,
    required this.isSelected,
    required this.removeLabel,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.onToggleExpanded,
    required this.onEditPressed,
    required this.onPrimaryActionPressed,
    required this.onQuickShoppingListActionPressed,
    required this.onSwapCandidatePressed,
    required this.onRemovePressed,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final bool isSelectionMode;
  final bool isSelected;
  final String removeLabel;
  final String editLabel;
  final String swapCandidateLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onEditPressed;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback? onQuickShoppingListActionPressed;
  final VoidCallback onSwapCandidatePressed;
  final VoidCallback? onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelectionMode)
            InventoryItemRowMainSection(
              item: layoutData.snapshot,
              viewData: layoutData.viewData,
              isExpanded: isExpanded,
              onPrimaryActionPressed: onPrimaryActionPressed,
              onQuickShoppingListActionPressed:
                  onQuickShoppingListActionPressed,
              showSelectionCheckbox: isSelectionMode,
              isSelected: isSelected,
            )
          else
            InventoryItemRowMainSection(
              item: layoutData.snapshot,
              viewData: layoutData.viewData,
              isExpanded: isExpanded,
              onPrimaryActionPressed: onPrimaryActionPressed,
              onQuickShoppingListActionPressed:
                  onQuickShoppingListActionPressed,
              showSelectionCheckbox: isSelectionMode,
              isSelected: isSelected,
              expandIndicatorKey: Key(
                'inventory_item_row_expand_indicator_'
                '${layoutData.snapshot.itemId}',
              ),
            ),
          SizedBox(height: isExpanded ? AppSpacing.xxs : 0),
          InventoryItemRowExpandSection(
            isExpanded: isExpanded,
            viewData: layoutData.viewData,
            colorScheme: layoutData.colorScheme,
            removeLabel: removeLabel,
            editLabel: editLabel,
            swapCandidateLabel: swapCandidateLabel,
            onEditPressed: onEditPressed,
            onRemovePressed: onRemovePressed,
            onSwapCandidatePressed: onSwapCandidatePressed,
          ),
        ],
      ),
    );
  }
}
