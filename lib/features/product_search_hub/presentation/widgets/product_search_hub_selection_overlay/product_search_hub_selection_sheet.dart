import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_selection_overlay/'
    'product_search_hub_selection_overlay.dart';

/// Shows selected product search hub items.
Future<void> showProductSearchHubSelectionSheet({
  required BuildContext context,
  required List<ProductSearchHubSavedSelection> Function() selections,
  required bool Function() isSaving,
  required Future<void> Function(ProductSearchHubSavedSelection selection)
  onRemoveSelection,
}) async {
  if (selections().isEmpty) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return ProductSearchHubSelectionSheet(
            items: [
              for (final selection in selections()) selection.item,
            ],
            isSaving: isSaving(),
            onRemovePressed: (item) async {
              final selection = _selectionForItem(selections(), item.id);
              if (selection == null) {
                return;
              }
              final removeFuture = onRemoveSelection(selection);
              setSheetState(() {});
              await removeFuture;
              if (!sheetContext.mounted) {
                return;
              }
              setSheetState(() {});
              if (selections().isEmpty) {
                sheetContext.pop();
              }
            },
          );
        },
      );
    },
  );
}

ProductSearchHubSavedSelection? _selectionForItem(
  List<ProductSearchHubSavedSelection> selections,
  String itemId,
) {
  for (final selection in selections) {
    if (selection.item.id == itemId) {
      return selection;
    }
  }
  return null;
}
