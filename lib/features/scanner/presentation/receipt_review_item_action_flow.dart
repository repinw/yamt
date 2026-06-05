import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_editor/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_receipt_candidate_picker_sheet.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_review_sheet_controller.dart';
import 'package:yamt/features/scanner/presentation/'
    'receipt_review_manual_product_selection_flow.dart';

/// Runs item-level edit and product-selection flows for receipt review.
class ReceiptReviewItemActionFlow {
  /// Creates item action flow helper.
  const ReceiptReviewItemActionFlow({
    required this.context,
    required this.controllerProvider,
    required this.isMounted,
  });

  /// Widget context that owns modal routes.
  final BuildContext context;

  /// Receipt review controller provider for the current sheet instance.
  final ReceiptReviewSheetControllerProvider controllerProvider;

  /// Whether the owning state is still mounted.
  final bool Function() isMounted;

  ProviderContainer get _container {
    return ProviderScope.containerOf(context, listen: false);
  }

  bool get _isActive => isMounted() && context.mounted;

  /// Opens the receipt item editor and applies the edited item.
  Future<void> openItemEditor(String itemId) async {
    final container = _container;
    if (container.read(controllerProvider).isSaving) {
      return;
    }
    final controller = container.read(controllerProvider.notifier);
    final draft = controller.draftForItemId(itemId);
    if (draft == null || draft.item.isDiscount) {
      return;
    }

    final editedItem = await _showItemEditor(draft.item);
    if (!_isActive || editedItem == null) {
      return;
    }
    final currentContainer = _container;
    if (currentContainer.read(controllerProvider).isSaving) {
      return;
    }

    currentContainer
        .read(controllerProvider.notifier)
        .applyEditedItem(itemId, editedItem);
  }

  /// Opens the candidate picker and applies the selected correction.
  Future<void> openCandidatePicker(String itemId) async {
    final container = _container;
    final sheetState = container.read(controllerProvider);
    if (sheetState.isSaving || sheetState.candidateLoadingItemId != null) {
      return;
    }

    final controller = container.read(controllerProvider.notifier);
    final draft = await controller.prepareDraftForCandidateSelection(itemId);
    if (!_isActive || draft == null || !draft.canBeSavedToInventory) {
      return;
    }
    final currentContainer = _container;
    if (currentContainer.read(controllerProvider).isSaving) {
      return;
    }

    final selection = await _showCandidatePicker(draft);
    if (!_isActive || selection == null) {
      return;
    }
    await _applyCandidateSelection(itemId, selection);
  }

  Future<void> _applyCandidateSelection(
    String itemId,
    ReceiptCandidatePickerSelection selection,
  ) async {
    final container = _container;
    if (container.read(controllerProvider).isSaving) {
      return;
    }

    switch (selection.kind) {
      case ReceiptCandidatePickerSelectionKind.candidate:
        final candidateId = selection.candidateId;
        if (candidateId == null) {
          return;
        }
        container
            .read(controllerProvider.notifier)
            .selectCandidate(itemId, candidateId);
      case ReceiptCandidatePickerSelectionKind.manualEntry:
        await _openManualProductEntry(itemId);
    }
  }

  Future<void> _openManualProductEntry(String itemId) async {
    final container = _container;
    if (container.read(controllerProvider).isSaving) {
      return;
    }
    final controller = container.read(controllerProvider.notifier);
    final draft = controller.draftForItemId(itemId);
    if (draft == null) {
      return;
    }

    final result = await openReceiptReviewManualProductFlow(
      context: context,
      item: draft.item,
    );
    if (!_isActive || result == null) {
      return;
    }
    final currentContainer = _container;
    if (currentContainer.read(controllerProvider).isSaving) {
      return;
    }

    currentContainer
        .read(controllerProvider.notifier)
        .applyManualProductResult(
          itemId: itemId,
          item: result.item,
          selectedProduct: result.selectedProduct,
          selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
        );
  }

  Future<ReceiptCandidatePickerSelection?> _showCandidatePicker(
    ReceiptReviewItemDraft draft,
  ) {
    return showModalBottomSheet<ReceiptCandidatePickerSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return InventoryReceiptCandidatePickerSheet(draft: draft);
      },
    );
  }

  Future<InventoryItem?> _showItemEditor(InventoryItem item) {
    return showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return InventoryReceiptItemEditorSheet(item: item);
      },
    );
  }
}
