part of 'meal_template_detail_page.dart';

class _MealTemplateIngredientCard extends StatefulWidget {
  const _MealTemplateIngredientCard({
    required this.row,
    required this.inventoryItems,
    this.onAddToShoppingListPressed,
    this.onToggleIgnoredPressed,
    this.onAssignmentChanged,
  });

  final _IngredientRowData row;
  final List<InventoryItem> inventoryItems;
  final Future<void> Function()? onAddToShoppingListPressed;
  final Future<void> Function()? onToggleIgnoredPressed;
  final void Function(List<String> inventoryItemIds)? onAssignmentChanged;

  @override
  State<_MealTemplateIngredientCard> createState() =>
      _MealTemplateIngredientCardState();
}

class _MealTemplateIngredientCardState
    extends State<_MealTemplateIngredientCard> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final assignedItems = resolveInventoryItemsById(
      inventoryItemIds: widget.row.assignedInventoryItemIds,
      inventoryItems: widget.inventoryItems,
    );
    final missingAssignedCount =
        widget.row.assignedInventoryItemIds.length - assignedItems.length;
    final suggestions = widget.row.isIgnored
        ? const <InventoryItem>[]
        : matchInventoryItemsForIngredient(
            ingredient: widget.row.name,
            inventoryItems: widget.inventoryItems,
          ).take(3).toList(growable: false);
    final previewImageUrl = _resolvePreviewImageUrl(
      assignedItems: assignedItems,
      suggestions: suggestions,
    );
    final subtitle = _buildIngredientSubtitle(
      l10n: l10n,
      row: widget.row,
      assignedItems: assignedItems,
    );
    final ingredientStyle = widget.row.isIgnored
        ? textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: colors.onSurfaceVariant,
          )
        : textTheme.titleMedium;
    final amountStyle = widget.row.isIgnored
        ? textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)
        : textTheme.bodyMedium;

    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    _IngredientPreviewThumbnail(imageUrl: previewImageUrl),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.row.name, style: ingredientStyle),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(subtitle, style: amountStyle),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed:
                          widget.inventoryItems.isEmpty ||
                              widget.onAssignmentChanged == null
                          ? null
                          : () => _selectInventoryAssignments(
                              context: context,
                              row: widget.row,
                              inventoryItems: widget.inventoryItems,
                              onAssignmentChanged: widget.onAssignmentChanged!,
                            ),
                      tooltip: widget.row.assignedInventoryItemIds.isEmpty
                          ? l10n.preparedMealTemplateDetailAssignAction
                          : l10n.preparedMealTemplateDetailChangeAssignmentAction,
                      icon: const Icon(Icons.sync_alt_rounded),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: AppSpacing.md),
              if (assignedItems.isNotEmpty) ...[
                Text(
                  l10n.preparedMealTemplateDetailAssignedFromInventoryTitle,
                  style: textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: assignedItems
                      .map(
                        (item) => Chip(
                          label: Text(
                            '${item.name} • '
                            '${_inventoryAmountLabel(item)}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ] else if (suggestions.isNotEmpty) ...[
                Text(
                  l10n.preparedMealTemplateDetailMatchingInventoryItemsTitle,
                  style: textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  suggestions.map((item) => item.name).join(', '),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (missingAssignedCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.preparedMealTemplateDetailMissingAssignedItems(
                    missingAssignedCount,
                  ),
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ],
              if (widget.row.rawIngredient != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.row.isIgnored
                          ? null
                          : widget.onAddToShoppingListPressed,
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text(
                        l10n.preparedMealTemplateDetailAddToShoppingListAction,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onToggleIgnoredPressed,
                      child: Text(
                        widget.row.isIgnored
                            ? l10n.preparedMealTemplateDetailUnignoreAction
                            : l10n.preparedMealTemplateDetailIgnoreAction,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _IngredientPreviewThumbnail extends StatelessWidget {
  const _IngredientPreviewThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 48,
        child: normalizedImageUrl == null
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Image.network(
                normalizedImageUrl,
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
