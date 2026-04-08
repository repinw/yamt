import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_amount_input_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_action_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_expand_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_main_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_progress.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_amount_unit_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryItemRow extends ConsumerStatefulWidget {
  const InventoryItemRow({
    super.key,
    required this.expansionStorageKey,
    required this.item,
    required this.l10n,
    required this.showBarcodeMarkers,
    required this.isAlreadyInShoppingList,
    required this.onDeletePressed,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onStartSelection,
    this.onSelectionToggle,
  });

  final String expansionStorageKey;
  final InventoryItem item;
  final AppLocalizations l10n;
  final bool showBarcodeMarkers;
  final bool isAlreadyInShoppingList;
  final Future<bool> Function(String itemId) onDeletePressed;
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatPressed;
  final Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayPressed;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onStartSelection;
  final VoidCallback? onSelectionToggle;

  @override
  ConsumerState<InventoryItemRow> createState() => _InventoryItemRowState();
}

class _InventoryItemRowState extends ConsumerState<InventoryItemRow> {
  var _isExpanded = false;
  var _isWorking = false;
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
      showBarcodeMarkers: widget.showBarcodeMarkers,
      isSelectionMode: widget.isSelectionMode,
    );
    final onPrimaryActionPressed = _buildPrimaryActionPressed(layoutData);

    return _InventoryItemRowCard(
      layoutData: layoutData,
      isExpanded: widget.isSelectionMode ? false : _isExpanded,
      isSelectionMode: widget.isSelectionMode,
      isSelected: widget.isSelected,
      deleteLabel: widget.l10n.inventoryItemDeleteAction,
      editLabel: widget.l10n.inventoryReceiptReviewEditAction,
      swapCandidateLabel: widget.l10n.inventoryItemSwapCandidateAction,
      throwAwayLabel: widget.l10n.inventoryItemThrowAwayAction,
      onToggleExpanded: widget.isSelectionMode
          ? (widget.onSelectionToggle ?? () {})
          : _toggleExpanded,
      onDeletePressed: _isWorking ? () {} : _onDeletePressed,
      onEditPressed: _isWorking ? () {} : _onEditPressed,
      onPrimaryActionPressed: onPrimaryActionPressed,
      onSwapCandidatePressed: _isWorking ? () {} : _onSwapCandidatePressed,
      onThrowAwayPressed: layoutData.isAdjustActionEnabled
          ? _onThrowAwayPressed
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
    if (layoutData.isBuyAgainPrimaryAction) {
      return _onBuyAgainPressed;
    }
    return _onEatPressed;
  }

  _InventoryItemRowLayoutData _buildLayoutData(
    BuildContext context, {
    required bool isAlreadyInShoppingList,
    required bool showBarcodeMarkers,
    required bool isSelectionMode,
  }) {
    final item = widget.item;
    final hasAdjustableAmount = _buildInputConfig(item) != null;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return _InventoryItemRowLayoutData.fromItem(
      context: context,
      item: item,
      l10n: widget.l10n,
      localeName: localeName,
      hasAdjustableAmount: hasAdjustableAmount,
      isWorking: _isWorking,
      isAlreadyInShoppingList: isAlreadyInShoppingList,
      showBarcodeMarkers: showBarcodeMarkers,
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

  void _onDeletePressed() {
    unawaited(
      _actionCoordinator.runAction(
        () => widget.onDeletePressed(widget.item.id),
      ),
    );
  }

  void _onEatPressed() {
    unawaited(_requestEatAmountAndRunAction(action: widget.onEatPressed));
  }

  void _onThrowAwayPressed() {
    unawaited(_requestDiscardAndRunAction());
  }

  void _onEditPressed() {
    _showActionSnackBar(widget.l10n.commonNotImplementedYet);
  }

  void _onBuyAgainPressed() {
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

  Future<void> _requestDiscardAndRunAction() async {
    final config = _buildInputConfig(widget.item);
    if (config == null) {
      return;
    }

    final amount = await showDialog<int>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return InventoryItemAmountInputDialog(
          title: widget.l10n.inventoryItemThrowAwayAction,
          confirmLabel: widget.l10n.inventoryItemThrowAwayAction,
          cancelLabel: widget.l10n.inventoryReceiptReviewCancelAction,
          fieldLabel: config.fieldLabel,
          invalidAmountMessage: widget.l10n.inventoryReceiptReviewInvalidNumber,
          maxAmount: config.maxAmount,
          suffixText: config.suffixText,
        );
      },
    );
    if (!mounted || amount == null) {
      return;
    }

    final reason = await showInventoryDiscardReasonDialog(
      context,
      useRootNavigator: false,
    );
    if (!mounted || reason == null) {
      return;
    }

    await _actionCoordinator.runAction(
      () => widget.onThrowAwayPressed(widget.item.id, amount, reason),
    );
  }

  void _showActionSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
    );
  }
}

class _ItemAmountInputConfig {
  const _ItemAmountInputConfig({
    required this.maxAmount,
    required this.fieldLabel,
    required this.suffixText,
  });

  final int maxAmount;
  final String fieldLabel;
  final String? suffixText;
}

class _InventoryItemRowLayoutData {
  const _InventoryItemRowLayoutData({
    required this.colorScheme,
    required this.snapshot,
    required this.viewData,
    required this.isPrimaryActionEnabled,
    required this.isBuyAgainPrimaryAction,
    required this.isAdjustActionEnabled,
  });

  factory _InventoryItemRowLayoutData.fromItem({
    required BuildContext context,
    required InventoryItem item,
    required AppLocalizations l10n,
    required String localeName,
    required bool hasAdjustableAmount,
    required bool isWorking,
    required bool isAlreadyInShoppingList,
    required bool showBarcodeMarkers,
    required bool isSelectionMode,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isBuyAgainPrimaryAction = item.isFullyConsumed;
    final eatActionColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final buyAgainActionColors =
        AppInventoryBuyAgainActionColors.fromColorScheme(colors);
    final progress = const InventoryItemProgressCalculator().fromItem(item);
    final brand = item.brand?.trim() ?? '';
    final hasBrand = brand.isNotEmpty;
    final isAdjustActionEnabled =
        !isSelectionMode && !isWorking && hasAdjustableAmount;
    final isPrimaryActionEnabled =
        !isSelectionMode &&
        !isWorking &&
        (isBuyAgainPrimaryAction
            ? !isAlreadyInShoppingList
            : isAdjustActionEnabled);

    final marker = showBarcodeMarkers
        ? _barcodeStatusMarker(
            l10n: l10n,
            colorScheme: colors,
            status: item.barcodeStatus,
          )
        : null;
    final currency = buildCurrencyFormat(
      locale: localeName,
      currencyCode: item.currencyCode,
    );

    return _InventoryItemRowLayoutData(
      colorScheme: colors,
      snapshot: InventoryItemRowSnapshot.fromItem(item),
      viewData: InventoryItemRowViewData(
        rowBorderColor: AppInventoryEditorialSurfaces.ghostBorder(colors),
        expandedRowBorderColor: colors.primary.withValues(alpha: 0.2),
        unitPriceLabel:
            '${l10n.inventoryReceiptReviewFieldUnitPrice}: '
            '${currency.format(item.unitPrice)}',
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
        statusText: marker?.text,
        statusColor: marker?.color,
        remainingRatio: progress.remainingRatio,
        remainingLabel: progress.remainingLabel,
        segmentedByUnits: progress.segmentedByUnits,
        isPrimaryActionEnabled: isPrimaryActionEnabled,
        isBuyAgainPrimaryAction: isBuyAgainPrimaryAction,
        showPrimaryActionText: !isBuyAgainPrimaryAction,
        primaryActionLabel: l10n.inventoryItemEatAction,
        eatActionBackgroundColor: isBuyAgainPrimaryAction
            ? buyAgainActionColors.backgroundColor
            : eatActionColors.backgroundColor,
        disabledActionBackgroundColor: AppInventoryEditorialSurfaces.section(
          colors,
        ),
        eatActionBorderColor: isBuyAgainPrimaryAction
            ? buyAgainActionColors.borderColor
            : eatActionColors.borderColor,
        disabledActionBorderColor: AppInventoryEditorialSurfaces.ghostBorder(
          colors,
        ),
        primaryActionTooltip: isBuyAgainPrimaryAction
            ? l10n.inventoryItemBuyAgainAction
            : l10n.inventoryItemEatAction,
        primaryActionIcon: isBuyAgainPrimaryAction
            ? Icons.shopping_cart_checkout_rounded
            : Icons.restaurant_menu,
        eatActionIconColor: isBuyAgainPrimaryAction
            ? buyAgainActionColors.iconColor
            : eatActionColors.iconColor,
        disabledActionIconColor: colors.onSurfaceVariant,
        nutritionMetrics: _buildNutritionMetrics(l10n, item),
      ),
      isPrimaryActionEnabled: isPrimaryActionEnabled,
      isBuyAgainPrimaryAction: isBuyAgainPrimaryAction,
      isAdjustActionEnabled: isAdjustActionEnabled,
    );
  }

  final ColorScheme colorScheme;
  final InventoryItemRowSnapshot snapshot;
  final InventoryItemRowViewData viewData;
  final bool isPrimaryActionEnabled;
  final bool isBuyAgainPrimaryAction;
  final bool isAdjustActionEnabled;
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

({String text, Color color})? _barcodeStatusMarker({
  required AppLocalizations l10n,
  required ColorScheme colorScheme,
  required InventoryBarcodeStatus status,
}) {
  return switch (status) {
    InventoryBarcodeStatus.resolved => null,
    InventoryBarcodeStatus.uncertain => (
      text: l10n.inventoryBarcodeStatusUncertain,
      color: colorScheme.secondary,
    ),
    InventoryBarcodeStatus.pending => (
      text: l10n.inventoryBarcodeStatusPending,
      color: colorScheme.tertiary,
    ),
    InventoryBarcodeStatus.missing => (
      text: l10n.inventoryBarcodeStatusMissing,
      color: colorScheme.error,
    ),
  };
}

class _InventoryItemRowCard extends StatelessWidget {
  const _InventoryItemRowCard({
    required this.layoutData,
    required this.isExpanded,
    required this.isSelectionMode,
    required this.isSelected,
    required this.deleteLabel,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.throwAwayLabel,
    required this.onToggleExpanded,
    required this.onDeletePressed,
    required this.onEditPressed,
    required this.onPrimaryActionPressed,
    required this.onSwapCandidatePressed,
    required this.onThrowAwayPressed,
    required this.onStartSelection,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final bool isSelectionMode;
  final bool isSelected;
  final String deleteLabel;
  final String editLabel;
  final String swapCandidateLabel;
  final String throwAwayLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback onSwapCandidatePressed;
  final VoidCallback? onThrowAwayPressed;
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
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: isExpanded ? 48 : 30,
            offset: Offset(0, isExpanded ? 24 : 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleExpanded,
            onLongPress: isSelectionMode ? null : onStartSelection,
            child: _InventoryItemRowBody(
              layoutData: layoutData,
              isExpanded: isExpanded,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              deleteLabel: deleteLabel,
              editLabel: editLabel,
              swapCandidateLabel: swapCandidateLabel,
              throwAwayLabel: throwAwayLabel,
              onToggleExpanded: onToggleExpanded,
              onDeletePressed: onDeletePressed,
              onEditPressed: onEditPressed,
              onPrimaryActionPressed: onPrimaryActionPressed,
              onSwapCandidatePressed: onSwapCandidatePressed,
              onThrowAwayPressed: onThrowAwayPressed,
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
    required this.deleteLabel,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.throwAwayLabel,
    required this.onToggleExpanded,
    required this.onDeletePressed,
    required this.onEditPressed,
    required this.onPrimaryActionPressed,
    required this.onSwapCandidatePressed,
    required this.onThrowAwayPressed,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final bool isSelectionMode;
  final bool isSelected;
  final String deleteLabel;
  final String editLabel;
  final String swapCandidateLabel;
  final String throwAwayLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback onSwapCandidatePressed;
  final VoidCallback? onThrowAwayPressed;

  static const _expandIndicatorWidth = 42.0;
  static const _expandIndicatorHeight = 16.0;
  static const _expandIndicatorIconSize = 14.0;
  static const _expandIndicatorLeftInset =
      (AppInventoryEditorial.categoryTileSize - _expandIndicatorWidth) / 2;
  static const _collapsedExpandIndicatorBottomGap = 5.0;
  static const _expandIndicatorBottomOffset =
      AppSpacing.xl - _collapsedExpandIndicatorBottomGap;

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
              onPrimaryActionPressed: onPrimaryActionPressed,
              showSelectionCheckbox: isSelectionMode,
              isSelected: isSelected,
            )
          else
            Stack(
              clipBehavior: Clip.none,
              children: [
                InventoryItemRowMainSection(
                  item: layoutData.snapshot,
                  viewData: layoutData.viewData,
                  onPrimaryActionPressed: onPrimaryActionPressed,
                  showSelectionCheckbox: isSelectionMode,
                  isSelected: isSelected,
                ),
                Positioned(
                  left: _expandIndicatorLeftInset,
                  bottom: -_expandIndicatorBottomOffset,
                  child: InventoryExpandIndicator(
                    isExpanded: isExpanded,
                    width: _expandIndicatorWidth,
                    height: _expandIndicatorHeight,
                    iconSize: _expandIndicatorIconSize,
                    rotationKey: Key(
                      'inventory_item_row_expand_indicator_'
                      '${layoutData.snapshot.itemId}',
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: isExpanded ? AppSpacing.md : 0),
          InventoryItemRowExpandSection(
            isExpanded: isExpanded,
            viewData: layoutData.viewData,
            colorScheme: layoutData.colorScheme,
            deleteLabel: deleteLabel,
            editLabel: editLabel,
            swapCandidateLabel: swapCandidateLabel,
            throwAwayLabel: throwAwayLabel,
            onDeletePressed: onDeletePressed,
            onEditPressed: onEditPressed,
            onThrowAwayPressed: onThrowAwayPressed,
            onSwapCandidatePressed: onSwapCandidatePressed,
          ),
        ],
      ),
    );
  }
}
