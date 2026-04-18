part of 'meal_template_detail_page.dart';

class _MealTemplateIngredientCard extends StatelessWidget {
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
  final void Function(MealTemplateIngredientAssignmentSelection selection)?
  onAssignmentChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assignedItems = resolveInventoryItemsById(
      inventoryItemIds: row.assignedInventoryItemIds,
      inventoryItems: inventoryItems,
    );
    final suggestions = row.isIgnored
        ? const <InventoryItem>[]
        : matchInventoryItemsForIngredient(
            ingredient: row.name,
            inventoryItems: inventoryItems,
            localeCode: l10n.localeName,
          ).take(3).toList(growable: false);
    final missingAssignedCount =
        row.assignedInventoryItemIds.length - assignedItems.length;
    final previewImageUrl = _resolvePreviewImageUrl(
      assignedItems: assignedItems,
      suggestions: suggestions,
    );
    final effectiveRequirement = row.requirement == null
        ? null
        : resolveEffectiveRequirementForItems(
            requirement: row.requirement!,
            assignedItems: assignedItems,
            amountConversion: row.amountConversion,
          );
    final hasCompatibleAssignment = row.requirement == null
        ? assignedItems.isNotEmpty
        : effectiveRequirement != null;
    final state = _ingredientCardState(
      row: row,
      assignedItems: assignedItems,
      hasCompatibleAssignment: hasCompatibleAssignment,
    );

    return switch (state) {
      _IngredientCardState.ignored => _IgnoredIngredientCard(
        row: row,
        onToggleIgnoredPressed: onToggleIgnoredPressed,
      ),
      _IngredientCardState.matched => _MatchedIngredientCard(
        row: row,
        assignedItems: assignedItems,
        previewImageUrl: previewImageUrl,
        missingAssignedCount: missingAssignedCount,
        onAssignmentChanged: onAssignmentChanged,
        inventoryItems: inventoryItems,
      ),
      _IngredientCardState.missing => _MissingIngredientCard(
        row: row,
        onAddToShoppingListPressed: onAddToShoppingListPressed,
        onToggleIgnoredPressed: onToggleIgnoredPressed,
        onAssignmentChanged: onAssignmentChanged,
        inventoryItems: inventoryItems,
      ),
      _IngredientCardState.plain => _PlainIngredientCard(
        row: row,
        previewImageUrl: previewImageUrl,
      ),
    };
  }
}

class _MissingIngredientCard extends StatelessWidget {
  const _MissingIngredientCard({
    required this.row,
    required this.onAddToShoppingListPressed,
    required this.onToggleIgnoredPressed,
    required this.onAssignmentChanged,
    required this.inventoryItems,
  });

  final _IngredientRowData row;
  final Future<void> Function()? onAddToShoppingListPressed;
  final Future<void> Function()? onToggleIgnoredPressed;
  final void Function(MealTemplateIngredientAssignmentSelection selection)?
  onAssignmentChanged;
  final List<InventoryItem> inventoryItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_rounded, color: colors.tertiary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _ingredientDisplayTitle(row),
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.tertiary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _IngredientActionPill(
                  icon: Icons.shopping_cart_rounded,
                  label: l10n.preparedMealTemplateDetailListAction,
                  onPressed: onAddToShoppingListPressed == null
                      ? null
                      : () async {
                          await onAddToShoppingListPressed!();
                        },
                ),
                _IngredientActionPill(
                  icon: Icons.search_rounded,
                  label: l10n.preparedMealTemplateDetailSearchAction,
                  onPressed: onAssignmentChanged == null
                      ? null
                      : () async {
                          await _selectInventoryAssignments(
                            context: context,
                            row: row,
                            inventoryItems: inventoryItems,
                            onAssignmentChanged: onAssignmentChanged!,
                          );
                        },
                ),
                _IngredientActionPill(
                  icon: Icons.block_rounded,
                  label: l10n.preparedMealTemplateDetailIgnoreAction,
                  onPressed: onToggleIgnoredPressed == null
                      ? null
                      : () async {
                          await onToggleIgnoredPressed!();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchedIngredientCard extends StatelessWidget {
  const _MatchedIngredientCard({
    required this.row,
    required this.assignedItems,
    required this.previewImageUrl,
    required this.missingAssignedCount,
    required this.onAssignmentChanged,
    required this.inventoryItems,
  });

  final _IngredientRowData row;
  final List<InventoryItem> assignedItems;
  final String? previewImageUrl;
  final int missingAssignedCount;
  final void Function(MealTemplateIngredientAssignmentSelection selection)?
  onAssignmentChanged;
  final List<InventoryItem> inventoryItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final assignedLabel = _assignedInventoryLabel(
      l10n: l10n,
      assignedItems: assignedItems,
    );

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 18,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ingredientDisplayTitle(row),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _IngredientPreviewThumbnail(
                        imageUrl: previewImageUrl,
                        size: 28,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          assignedLabel,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (row.amountConversion != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.preparedMealTemplateDetailConversionSummary(
                        _conversionSourceUnitLabel(
                          requirement: row.requirement,
                          l10n: l10n,
                        ),
                        row.amountConversion!.amountPerPiece,
                        row.amountConversion!.unit.code,
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (missingAssignedCount > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.preparedMealTemplateDetailMissingAssignedItems(
                        missingAssignedCount,
                      ),
                      style: textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAssignmentChanged == null
                  ? null
                  : () async {
                      await _selectInventoryAssignments(
                        context: context,
                        row: row,
                        inventoryItems: inventoryItems,
                        onAssignmentChanged: onAssignmentChanged!,
                      );
                    },
              child: Text(l10n.preparedMealTemplateDetailSwapAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _IgnoredIngredientCard extends StatelessWidget {
  const _IgnoredIngredientCard({
    required this.row,
    required this.onToggleIgnoredPressed,
  });

  final _IngredientRowData row;
  final Future<void> Function()? onToggleIgnoredPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        color: colors.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
        blurRadius: 18,
        shadowOffset: const Offset(0, 10),
      ),
      child: Opacity(
        opacity: 0.82,
        child: Padding(
          padding: AppInsets.card,
          child: Row(
            children: [
              Icon(
                Icons.visibility_off_rounded,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _ingredientDisplayTitle(row),
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colors.onSurfaceVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onToggleIgnoredPressed == null
                    ? null
                    : () async {
                        await onToggleIgnoredPressed!();
                      },
                child: Text(l10n.preparedMealTemplateDetailRestoreAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainIngredientCard extends StatelessWidget {
  const _PlainIngredientCard({
    required this.row,
    required this.previewImageUrl,
  });

  final _IngredientRowData row;
  final String? previewImageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: [
            _IngredientPreviewThumbnail(imageUrl: previewImageUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(row.amountLabel, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientActionPill extends StatelessWidget {
  const _IngredientActionPill({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(999);

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed == null
                    ? colors.onSurfaceVariant
                    : colors.onSurface,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onPressed == null
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientPreviewThumbnail extends StatelessWidget {
  const _IngredientPreviewThumbnail({
    required this.imageUrl,
    this.size = 48,
    this.borderRadius = 12,
  });

  final String? imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.square(
        dimension: size,
        child: normalizedImageUrl == null
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: size < 32 ? 16 : 20,
                  color: colors.onSurfaceVariant,
                ),
              )
            : AppCachedNetworkImage(
                imageUrl: normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: size < 32 ? 16 : 20,
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Defines meal template ingredient card test harness.
@visibleForTesting
class MealTemplateIngredientCardTestHarness extends StatelessWidget {
  /// The meal template ingredient card test harness.
  const MealTemplateIngredientCardTestHarness({
    required this.name,
    required this.amountLabel,
    required this.inventoryItems,
    super.key,
    this.rawIngredient,
    this.isIgnored = false,
    this.assignedInventoryItemIds = const <String>[],
    this.amountConversion,
    this.onAddToShoppingListPressed,
    this.onToggleIgnoredPressed,
    this.onAssignmentChanged,
  });

  /// The name.
  final String name;

  /// The amount label.
  final String amountLabel;

  /// The raw ingredient.
  final String? rawIngredient;

  /// Whether ignored.
  final bool isIgnored;

  /// The assigned inventory item ids.
  final List<String> assignedInventoryItemIds;

  /// The inventory items.
  final List<InventoryItem> inventoryItems;

  /// The on add to shopping list pressed.
  final Future<void> Function()? onAddToShoppingListPressed;

  /// The on toggle ignored pressed.
  final Future<void> Function()? onToggleIgnoredPressed;

  /// Documented member.
  final void Function(MealTemplateIngredientAssignmentSelection selection)?
  onAssignmentChanged;

  /// The amount conversion.
  final RecipeIngredientAmountConversion? amountConversion;

  @override
  Widget build(BuildContext context) {
    return _MealTemplateIngredientCard(
      row: _IngredientRowData(
        name: name,
        amountLabel: amountLabel,
        rawIngredient: rawIngredient,
        isIgnored: isIgnored,
        assignedInventoryItemIds: assignedInventoryItemIds,
        amountConversion: amountConversion,
      ),
      inventoryItems: inventoryItems,
      onAddToShoppingListPressed: onAddToShoppingListPressed,
      onToggleIgnoredPressed: onToggleIgnoredPressed,
      onAssignmentChanged: onAssignmentChanged,
    );
  }
}
