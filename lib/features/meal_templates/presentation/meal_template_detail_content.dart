part of 'meal_template_detail_page.dart';

class _MealTemplateDetailContent extends ConsumerWidget {
  const _MealTemplateDetailContent({
    required this.template,
    required this.selectedPortions,
    required this.inventoryItems,
    required this.recipeIngredientAssignments,
    required this.recipeIngredientAmountConversions,
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

  static const _maxContentWidth = 760.0;
  static const _footerHeight = 164.0;
  static const _footerHeightWithSave = 220.0;
  static const _topBarContentHeight = 76.0;

  final PreparedMeal template;
  final int selectedPortions;
  final List<InventoryItem> inventoryItems;
  final Map<String, List<String>> recipeIngredientAssignments;
  final Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions;
  final bool hasAssignmentChanges;
  final bool isCreatingMeal;
  final bool isSavingTemplate;
  final VoidCallback? onDecreasePortions;
  final VoidCallback onIncreasePortions;
  final void Function({
    required String ingredient,
    required List<String> inventoryItemIds,
    required RecipeIngredientAmountConversion? amountConversion,
  })
  onAssignmentChanged;
  final Future<void> Function() onCreateMealPressed;
  final Future<void> Function() onAddIngredientsToShoppingListPressed;
  final Future<void> Function()? onSaveTemplatePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final topBarReservedHeight =
        MediaQuery.paddingOf(context).top + _topBarContentHeight;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final ingredientRows = _buildIngredientRows(
      template: template,
      recipeIngredientAssignments: recipeIngredientAssignments,
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      selectedPortions: selectedPortions,
      ingredientParser: ref.read(templateIngredientParserProvider),
    );
    final canCreateMeal = ingredientRows.isNotEmpty;
    final showFooter = template.recipeIngredients.isNotEmpty;
    final scrollBottomPadding = showFooter
        ? hasAssignmentChanges
              ? _footerHeightWithSave
              : _footerHeight
        : AppSpacing.xxxxl;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.backdropGradient(colors),
      ),
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: topBarReservedHeight,
              bottom: scrollBottomPadding,
            ),
            children: [
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    children: [
                      _MealTemplateHeroSection(
                        templateName: template.name,
                        imageBytes: storedImageBytes,
                        imageUrl: template.imageUrl,
                        portionsLabel: l10n.preparedMealTemplatePortions(
                          selectedPortions,
                        ),
                        basePortionsLabel: l10n
                            .preparedMealTemplateDetailBasePortions(
                              _defaultPortions(template.totalPortions),
                            ),
                        onDecreasePortions: onDecreasePortions,
                        onIncreasePortions: onIncreasePortions,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xxxxl,
                        ),
                        child: ingredientRows.isEmpty
                            ? _MealTemplateEmptyIngredientsCard(
                                message: l10n
                                    .preparedMealTemplateDetailNoIngredients,
                              )
                            : Column(
                                children: [
                                  for (final row in ingredientRows) ...[
                                    _MealTemplateIngredientCard(
                                      row: row,
                                      inventoryItems: inventoryItems,
                                      onAddToShoppingListPressed:
                                          row.rawIngredient == null
                                          ? null
                                          : () => _addIngredientToShoppingList(
                                              context: context,
                                              ref: ref,
                                              shoppingListLabel:
                                                  _shoppingListLabelForRow(
                                                    row: row,
                                                    inventoryItems:
                                                        inventoryItems,
                                                  ),
                                            ),
                                      onToggleIgnoredPressed:
                                          row.rawIngredient == null
                                          ? null
                                          : () => _toggleIgnored(
                                              context: context,
                                              ref: ref,
                                              templateId: template.id,
                                              ingredient: row.rawIngredient!,
                                              isIgnored: !row.isIgnored,
                                            ),
                                      onAssignmentChanged:
                                          row.rawIngredient == null
                                          ? null
                                          : (selection) {
                                              onAssignmentChanged(
                                                ingredient: row.rawIngredient!,
                                                inventoryItemIds:
                                                    selection.inventoryItemIds,
                                                amountConversion:
                                                    selection.amountConversion,
                                              );
                                            },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _MealTemplateTopBar(
            title: l10n.preparedMealTemplateDetailMatchTitle(template.name),
            height: _topBarContentHeight,
          ),
          if (showFooter)
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: _MealTemplateFooter(
                  hasAssignmentChanges: hasAssignmentChanges,
                  isCreatingMeal: isCreatingMeal,
                  isSavingTemplate: isSavingTemplate,
                  canCreateMeal: canCreateMeal,
                  onSaveTemplatePressed: onSaveTemplatePressed,
                  onAddIngredientsToShoppingListPressed:
                      onAddIngredientsToShoppingListPressed,
                  onCreateMealPressed: onCreateMealPressed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
