part of 'meal_template_detail_page.dart';

class _MealTemplateDetailContent extends ConsumerWidget {
  const _MealTemplateDetailContent({
    required this.template,
    required this.selectedPortions,
    required this.recipeIngredientAssignments,
    required this.hasAssignmentChanges,
    required this.isCreatingMeal,
    required this.isSavingTemplate,
    required this.onDecreasePortions,
    required this.onIncreasePortions,
    required this.onAssignmentChanged,
    required this.onCreateMealPressed,
    required this.onAddIngredientsToShoppingListPressed,
    required this.onSaveTemplatePressed,
  });

  final PreparedMeal template;
  final int selectedPortions;
  final Map<String, List<String>> recipeIngredientAssignments;
  final bool hasAssignmentChanges;
  final bool isCreatingMeal;
  final bool isSavingTemplate;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;
  final void Function({
    required String ingredient,
    required List<String> inventoryItemIds,
  })
  onAssignmentChanged;
  final Future<void> Function() onCreateMealPressed;
  final Future<void> Function() onAddIngredientsToShoppingListPressed;
  final Future<void> Function()? onSaveTemplatePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final inventoryItems =
        ref.watch(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    final recipeSourceHost = _recipeSourceHost(template.recipeUrl);
    final ingredientRows = _buildIngredientRows(
      template: template,
      recipeIngredientAssignments: recipeIngredientAssignments,
      selectedPortions: selectedPortions,
    );
    final canCreateMeal = ingredientRows.isNotEmpty;

    return ListView(
      padding: AppInsets.pageLarge,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreparedMealCover(
              label: template.name,
              imageBytes: storedImageBytes,
              imageUrl: template.imageUrl,
              size: 112,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (recipeSourceHost != null)
                    Text(
                      l10n.preparedMealTemplateRecipeSource(recipeSourceHost),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.preparedMealTemplateDetailBasePortions(
                      template.totalPortions,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: AppInsets.card,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.preparedMealPortionsLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.preparedMealTemplateDetailScaleHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDecreasePortions,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$selectedPortions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: onIncreasePortions,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.preparedMealIngredientsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (ingredientRows.isEmpty)
          Text(l10n.preparedMealTemplateDetailNoIngredients)
        else
          Column(
            children: [
              for (final row in ingredientRows) ...[
                _MealTemplateIngredientCard(
                  templateId: template.id,
                  row: row,
                  inventoryItems: inventoryItems,
                  onAssignmentChanged: row.rawIngredient == null
                      ? null
                      : (inventoryItemIds) {
                          onAssignmentChanged(
                            ingredient: row.rawIngredient!,
                            inventoryItemIds: inventoryItemIds,
                          );
                        },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        if (template.recipeIngredients.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (hasAssignmentChanges) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSavingTemplate || isCreatingMeal
                        ? null
                        : onSaveTemplatePressed,
                    child: Text(
                      isSavingTemplate
                          ? l10n.preparedMealTemplateDetailSavingAction
                          : l10n.preparedMealTemplateDetailSaveAction,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCreatingMeal || isSavingTemplate
                      ? null
                      : onAddIngredientsToShoppingListPressed,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    l10n.preparedMealTemplateDetailIngredientsToShoppingListAction,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      isCreatingMeal || isSavingTemplate || !canCreateMeal
                      ? null
                      : onCreateMealPressed,
                  icon: const Icon(Icons.restaurant_rounded),
                  label: Text(l10n.preparedMealCreateAction),
                ),
              ),
            ],
          ),
          if (!canCreateMeal) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.preparedMealTemplateDetailCreateMealHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ],
    );
  }
}
