// Internal detail split files expose widgets only to sibling files.
// Local imports avoid stale package resolution across worktrees.
// ignore_for_file: always_use_package_imports, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

import 'meal_template_detail_actions.dart';
import 'meal_template_detail_empty_ingredients_card.dart';
import 'meal_template_detail_footer.dart';
import 'meal_template_detail_helpers.dart';
import 'meal_template_detail_hero_section.dart';
import 'meal_template_detail_ingredient_card.dart';
import 'meal_template_detail_top_bar.dart';

class MealTemplateDetail extends ConsumerWidget {
  const MealTemplateDetail({
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
    super.key,
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
    final ingredientRows = buildIngredientRows(
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
                      MealTemplateHeroSection(
                        templateName: template.name,
                        imageBytes: storedImageBytes,
                        imageUrl: template.imageUrl,
                        portionsLabel: l10n.preparedMealTemplatePortions(
                          selectedPortions,
                        ),
                        basePortionsLabel: l10n
                            .preparedMealTemplateDetailBasePortions(
                              defaultPortions(template.totalPortions),
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
                            ? MealTemplateEmptyIngredientsCard(
                                message: l10n
                                    .preparedMealTemplateDetailNoIngredients,
                              )
                            : Column(
                                children: [
                                  for (final row in ingredientRows) ...[
                                    MealTemplateIngredientCard(
                                      row: row,
                                      inventoryItems: inventoryItems,
                                      onAddToShoppingListPressed:
                                          row.rawIngredient == null
                                          ? null
                                          : () => addIngredientToShoppingList(
                                              context: context,
                                              ref: ref,
                                              shoppingListLabel:
                                                  shoppingListLabelForRow(
                                                    row: row,
                                                    inventoryItems:
                                                        inventoryItems,
                                                  ),
                                            ),
                                      onToggleIgnoredPressed:
                                          row.rawIngredient == null
                                          ? null
                                          : () => toggleIgnored(
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
          MealTemplateTopBar(
            title: l10n.preparedMealTemplateDetailMatchTitle(template.name),
            height: _topBarContentHeight,
          ),
          if (showFooter)
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: MealTemplateFooter(
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
