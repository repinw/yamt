// Internal split widgets are public only so sibling files can import them.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_intro_inventory_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_assignment.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_widgets.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CookingFlowInventoryCheckCard extends ConsumerStatefulWidget {
  const CookingFlowInventoryCheckCard({
    required this.template,
    required this.targetPortions,
    required this.inventoryItems,
    required this.localeCode,
    required this.initialDraft,
    required this.shoppingBaselineInventoryItemIds,
    required this.resetSignal,
    required this.onRestartPressed,
    required this.onShoppingLabelsResolved,
    required this.onSelectionStateChanged,
  });

  final PreparedMeal template;
  final int targetPortions;
  final List<InventoryItem> inventoryItems;
  final String localeCode;
  final CookingFlowIntroDraft? initialDraft;
  final List<String> shoppingBaselineInventoryItemIds;
  final int resetSignal;
  final Future<void> Function() onRestartPressed;
  final Future<void> Function(List<String> labels) onShoppingLabelsResolved;
  final ValueChanged<CookingFlowIntroSelectionState> onSelectionStateChanged;

  @override
  ConsumerState<CookingFlowInventoryCheckCard> createState() =>
      CookingFlowInventoryCheckCardState();
}

class CookingFlowInventoryCheckCardState
    extends ConsumerState<CookingFlowInventoryCheckCard> {
  late List<GlobalKey> _rowKeys;
  bool _syncScheduled = false;
  bool _hasScheduledDraftOverride = false;
  CookingFlowIntroDraft? _scheduledDraftOverride;

  @override
  void initState() {
    super.initState();
    _rowKeys = <GlobalKey>[];
    _scheduleControllerSync();
  }

  @override
  void didUpdateWidget(covariant CookingFlowInventoryCheckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template != widget.template ||
        oldWidget.localeCode != widget.localeCode ||
        oldWidget.resetSignal != widget.resetSignal) {
      _scheduleControllerSync();
      return;
    }
    if (oldWidget.targetPortions != widget.targetPortions) {
      final draft = ref
          .read(cookingFlowIntroInventoryControllerProvider.notifier)
          .currentDraft();
      _scheduleControllerSync(initialDraft: draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(
      cookingFlowIntroInventoryControllerProvider,
    );
    _syncRowKeys(inventoryState.rows.length);

    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.shopping_cart_outlined,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.cookflowInventoryCheckTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (inventoryState.hasAnySelections)
              TextButton.icon(
                onPressed: () {
                  unawaited(widget.onRestartPressed());
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.cookflowResetButton),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (inventoryState.rows.isEmpty)
          Text(
            l10n.cookflowEmptyIngredients,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        for (
          var index = 0;
          index < inventoryState.rows.length;
          index++
        ) ...<Widget>[
          () {
            final suggestedItem = _suggestedInventoryItemForIndex(index);
            return CookingFlowInventoryCheckRow(
              key: _rowKeys[index],
              row: inventoryState.rows[index],
              selectedAction: inventoryState.selectedActions[index],
              selectedSelections:
                  inventoryState.selectedInventorySelections[index],
              inventoryItems: widget.inventoryItems,
              localeCode: widget.localeCode,
              conflict: _conflictForIndex(index),
              conflictResolution: inventoryState.conflictResolutions[index],
              suggestedItem: suggestedItem,
              onAssignPressed: () => _selectInventoryItem(index),
              onEditPressed: () => _editIngredient(index),
              onShoppingPressed: () => _selectAction(
                index,
                CookingFlowInventoryRowAction.shoppingCart,
              ),
              onIgnorePressed: () => _selectAction(
                index,
                CookingFlowInventoryRowAction.ignored,
              ),
              onBuyRemainingPressed: () => _setConflictResolution(
                index,
                CookingFlowInventoryConflictResolution.buyRemaining,
              ),
              onAdjustTemplatePressed: () => _setConflictResolution(
                index,
                CookingFlowInventoryConflictResolution.adjustTemplate,
              ),
              onConvertUnitPressed: (amountPerPiece) =>
                  _convertUnitConflict(index, amountPerPiece),
              onWeighLaterPressed: () => _weighUnitConflictLater(index),
              onApplySuggestedItem: suggestedItem == null
                  ? null
                  : () => _applySuggestedInventoryItem(
                      index: index,
                      itemId: suggestedItem.id,
                    ),
            );
          }(),
          if (index != inventoryState.rows.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  void _scheduleControllerSync({CookingFlowIntroDraft? initialDraft}) {
    _hasScheduledDraftOverride = initialDraft != null;
    _scheduledDraftOverride = initialDraft;
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      final draft = _hasScheduledDraftOverride ? _scheduledDraftOverride : null;
      _hasScheduledDraftOverride = false;
      _scheduledDraftOverride = null;
      _syncController(draft: draft);
    });
  }

  void _syncController({CookingFlowIntroDraft? draft}) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .sync(
          CookingFlowIntroInventoryInput(
            template: widget.template,
            targetPortions: widget.targetPortions,
            localeCode: widget.localeCode,
            initialDraft: widget.initialDraft,
          ),
          draft: draft,
        );
    _syncRowKeys(
      ref.read(cookingFlowIntroInventoryControllerProvider).rows.length,
    );
    _notifySelectionState();
  }

  void _syncRowKeys(int rowCount) {
    if (_rowKeys.length == rowCount) {
      return;
    }
    if (_rowKeys.length > rowCount) {
      _rowKeys = _rowKeys.take(rowCount).toList(growable: false);
      return;
    }
    _rowKeys = <GlobalKey>[
      ..._rowKeys,
      for (var index = _rowKeys.length; index < rowCount; index++) GlobalKey(),
    ];
  }

  void _selectAction(int index, CookingFlowInventoryRowAction action) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .selectAction(index, action);
    _notifySelectionState();
    _scrollToNextRow(index);
  }

  Future<void> _selectInventoryItem(int index) async {
    final state = ref.read(cookingFlowIntroInventoryControllerProvider);
    final row = state.rows[index];
    final initialSelections = state.selectedInventorySelections[index];
    final selections = await showCookingFlowInventoryAssignmentSheet(
      context: context,
      ingredient: row.name,
      inventoryItems: widget.inventoryItems,
      localeCode: widget.localeCode,
      initialSelections: initialSelections,
    );
    if (!mounted || selections == null) {
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final resolvedShoppingLabels = notifier.shoppingLabelsResolvedByAssignment(
      index: index,
      nextSelections: selections,
      inventoryItems: widget.inventoryItems,
    );
    notifier.setInventorySelections(index: index, selections: selections);
    _notifySelectionState();
    if (resolvedShoppingLabels.isNotEmpty) {
      unawaited(widget.onShoppingLabelsResolved(resolvedShoppingLabels));
    }
    if (selections.isNotEmpty) {
      _scrollToNextRow(index);
    }
  }

  InventoryItem? _suggestedInventoryItemForIndex(int index) {
    return ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .suggestedInventoryItem(
          index: index,
          baselineInventoryItemIds: widget.shoppingBaselineInventoryItemIds,
          inventoryItems: widget.inventoryItems,
        );
  }

  void _applySuggestedInventoryItem({
    required int index,
    required String itemId,
  }) {
    final state = ref.read(cookingFlowIntroInventoryControllerProvider);
    final action = state.selectedActions[index];
    final nextSelections = switch (action) {
      CookingFlowInventoryRowAction.assigned =>
        <CookingFlowInventoryAssignmentSelection>[
          ...state.selectedInventorySelections[index],
          CookingFlowInventoryAssignmentSelection(itemId: itemId),
        ],
      _ => <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: itemId),
      ],
    };
    final notifier = ref.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final resolvedShoppingLabels = notifier.shoppingLabelsResolvedByAssignment(
      index: index,
      nextSelections: nextSelections,
      inventoryItems: widget.inventoryItems,
    );
    notifier.applySuggestedInventoryItem(index: index, itemId: itemId);
    _notifySelectionState();
    if (resolvedShoppingLabels.isNotEmpty) {
      unawaited(widget.onShoppingLabelsResolved(resolvedShoppingLabels));
    }
    _scrollToNextRow(index);
  }

  Future<void> _editIngredient(int index) async {
    final state = ref.read(cookingFlowIntroInventoryControllerProvider);
    final editedRow = await showCookingFlowIngredientEditSheet(
      context: context,
      row: state.rows[index],
    );
    if (!mounted || editedRow == null) {
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    container
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .editRow(index: index, row: editedRow);
    _notifySelectionState();
  }

  void _convertUnitConflict(int index, double amountPerPiece) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .convertUnitConflict(
          index: index,
          amountPerPiece: amountPerPiece,
          inventoryItems: widget.inventoryItems,
        );
    _notifySelectionState();
  }

  void _weighUnitConflictLater(int index) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .weighUnitConflictLater(
          index: index,
          inventoryItems: widget.inventoryItems,
        );
    _notifySelectionState();
  }

  void _notifySelectionState() {
    final selectionState = ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .selectionState(widget.inventoryItems);
    widget.onSelectionStateChanged(selectionState);
  }

  CookingFlowInventoryCheckConflict? _conflictForIndex(int index) {
    return ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .conflictForIndex(index, widget.inventoryItems);
  }

  void _setConflictResolution(
    int index,
    CookingFlowInventoryConflictResolution resolution,
  ) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .setConflictResolution(index: index, resolution: resolution);
    _notifySelectionState();
  }

  void _scrollToNextRow(int index) {
    final nextIndex = index + 1;
    if (nextIndex >= _rowKeys.length) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final nextContext = _rowKeys[nextIndex].currentContext;
      if (nextContext == null) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          nextContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.18,
        ),
      );
    });
  }
}
