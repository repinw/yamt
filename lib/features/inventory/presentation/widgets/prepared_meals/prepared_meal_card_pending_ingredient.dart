part of 'prepared_meal_card.dart';

class _PreparedMealPendingIngredientRow extends StatelessWidget {
  const _PreparedMealPendingIngredientRow({
    required this.ingredient,
    required this.suggestions,
    this.onAssignPressed,
    this.onIgnorePressed,
  });

  final String ingredient;
  final List<InventoryItem> suggestions;
  final VoidCallback? onAssignPressed;
  final VoidCallback? onIgnorePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final suggestionNames = suggestions.map((item) => item.name).join(', ');
    final previewImageUrl = suggestions.isEmpty
        ? null
        : suggestions.first.imageUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _PendingIngredientPreview(imageUrl: previewImageUrl),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    suggestions.isEmpty
                        ? l10n.preparedMealPendingIngredientUnassigned
                        : suggestionNames,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onAssignPressed,
              tooltip: l10n.preparedMealPendingIngredientAddAction,
              icon: const Icon(Icons.add_link_rounded),
            ),
            IconButton(
              onPressed: onIgnorePressed,
              tooltip: l10n.preparedMealPendingIngredientIgnoreAction,
              icon: const Icon(Icons.visibility_off_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingIngredientPreview extends StatelessWidget {
  const _PendingIngredientPreview({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 44,
        child: imageUrl == null
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Future<List<String>?> _showPendingIngredientSelectionSheet({
  required BuildContext context,
  required String ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  final l10n = AppLocalizations.of(context)!;
  final sortedItems = inventoryItems
      .where((item) => !item.isFullyConsumed)
      .toList(growable: false);
  sortedItems.sort((left, right) {
    final rightScore = _ingredientMatchScore(
      ingredient: ingredient,
      item: right,
    );
    final leftScore = _ingredientMatchScore(ingredient: ingredient, item: left);
    if (rightScore != leftScore) {
      return rightScore.compareTo(leftScore);
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final draftSelection = <String>{};
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
                      l10n.preparedMealPendingIngredientSelectionTitle,
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ingredient,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: sortedItems.isEmpty
                          ? Center(
                              child: Text(
                                l10n.preparedMealPendingIngredientSelectionEmpty,
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
                                  secondary: _PendingIngredientPreview(
                                    imageUrl: item.imageUrl,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    _pendingIngredientInventoryAmount(item),
                                  ),
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n.inventoryReceiptReviewCancelAction),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () => Navigator.of(
                            dialogContext,
                          ).pop(draftSelection.toList(growable: false)),
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
}
