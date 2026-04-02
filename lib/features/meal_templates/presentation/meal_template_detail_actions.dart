part of 'meal_template_detail_page.dart';

Future<void> _selectInventoryAssignments({
  required BuildContext context,
  required _IngredientRowData row,
  required List<InventoryItem> inventoryItems,
  required void Function(List<String> inventoryItemIds) onAssignmentChanged,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final sortedItems = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  sortedItems.sort((left, right) {
    final rightScore = _ingredientMatchScore(
      ingredientName: row.name,
      item: right,
    );
    final leftScore = _ingredientMatchScore(
      ingredientName: row.name,
      item: left,
    );
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  final selectedItemIds = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final draftSelection = row.assignedInventoryItemIds.toSet();
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.8;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preparedMealTemplateDetailSelectionTitle,
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      row.name,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: sortedItems.isEmpty
                          ? Center(
                              child: Text(
                                l10n.preparedMealTemplateDetailSelectionEmpty,
                              ),
                            )
                          : ListView.builder(
                              itemCount: sortedItems.length,
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                final isSelected = draftSelection.contains(
                                  item.id,
                                );
                                return CheckboxListTile(
                                  value: isSelected,
                                  contentPadding: EdgeInsets.zero,
                                  secondary: _IngredientPreviewThumbnail(
                                    imageUrl: item.imageUrl,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(_inventoryAmountLabel(item)),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked ?? false) {
                                        draftSelection.add(item.id);
                                      } else {
                                        draftSelection.remove(item.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => dialogContext.pop(),
                          child: Text(l10n.inventoryReceiptReviewCancelAction),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () => dialogContext.pop(
                            draftSelection.toList(growable: false),
                          ),
                          child: Text(
                            l10n.inventoryReceiptReviewManualDataSaveAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (!context.mounted || selectedItemIds == null) {
    return;
  }
  onAssignmentChanged(selectedItemIds);
}

Future<void> _addIngredientToShoppingList({
  required BuildContext context,
  required String shoppingListLabel,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final added = await container
      .read(shoppingListControllerProvider.notifier)
      .addItem(name: shoppingListLabel);
  if (!context.mounted || added) {
    return;
  }

  _showSnackBar(
    context,
    AppLocalizations.of(
      context,
    )!.preparedMealTemplateDetailAddIngredientShoppingFailed,
  );
}

Future<void> _addTemplateIngredientsToShoppingList({
  required BuildContext context,
  required List<_IngredientRowData> ingredientRows,
}) async {
  final rowsToAdd = ingredientRows
      .where((row) => !row.isIgnored)
      .toList(growable: false);
  if (rowsToAdd.isEmpty) {
    return;
  }

  final container = ProviderScope.containerOf(context, listen: false);
  final controller = container.read(shoppingListControllerProvider.notifier);
  var addedCount = 0;

  for (final row in rowsToAdd) {
    final added = await controller.addItem(name: _shoppingListLabel(row));
    if (!context.mounted) {
      return;
    }
    if (!added) {
      _showSnackBar(
        context,
        AppLocalizations.of(
          context,
        )!.preparedMealTemplateDetailAddIngredientsShoppingFailed,
      );
      return;
    }
    addedCount += 1;
  }

  _showSnackBar(
    context,
    AppLocalizations.of(
      context,
    )!.preparedMealTemplateDetailAddIngredientsShoppingSucceeded(addedCount),
  );
}

Future<void> _toggleIgnored({
  required BuildContext context,
  required String templateId,
  required String ingredient,
  required bool isIgnored,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final updated = await container
      .read(preparedMealTemplatesControllerProvider.notifier)
      .setRecipeIngredientIgnored(
        templateId: templateId,
        ingredient: ingredient,
        isIgnored: isIgnored,
      );
  if (!context.mounted || updated) {
    return;
  }

  _showSnackBar(
    context,
    AppLocalizations.of(context)!.preparedMealTemplateDetailIgnoreSaveFailed,
  );
}

void _showSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
