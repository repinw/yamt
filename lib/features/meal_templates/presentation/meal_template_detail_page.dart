// Local imports avoid stale package resolution across worktrees.
// ignore_for_file: always_use_package_imports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

import 'widgets/meal_template_detail/meal_template_detail.dart';
import 'widgets/meal_template_detail/meal_template_detail_actions.dart';
import 'widgets/meal_template_detail/meal_template_detail_helpers.dart';

/// Defines meal template detail page.
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
])
class MealTemplateDetailPage extends ConsumerStatefulWidget {
  /// The meal template detail page.
  const MealTemplateDetailPage({required this.templateId, super.key});

  /// The template id.
  final String templateId;

  @override
  ConsumerState<MealTemplateDetailPage> createState() =>
      _MealTemplateDetailPageState();
}

class _MealTemplateDetailPageState
    extends ConsumerState<MealTemplateDetailPage> {
  int? _selectedPortions;
  Map<String, List<String>>? _draftAssignments;
  Map<String, RecipeIngredientAmountConversion>? _draftAssignmentConversions;
  var _isCreatingMeal = false;
  var _isSavingTemplate = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(preparedMealTemplatesControllerProvider);

    return Scaffold(
      extendBody: true,
      body: templatesAsync.when(
        data: (templates) {
          final template = findTemplate(
            templates: templates,
            templateId: widget.templateId,
          );
          if (template == null) {
            return Center(
              child: Padding(
                padding: AppInsets.pageLarge,
                child: Text(l10n.preparedMealTemplateDetailNotFound),
              ),
            );
          }

          final selectedPortions =
              _selectedPortions ?? defaultPortions(template.totalPortions);
          final inventoryItems =
              ref.watch(inventoryItemsControllerProvider).asData?.value ??
              const <InventoryItem>[];
          final ingredientParser = ref.read(templateIngredientParserProvider);
          final assignments = effectiveAssignments(
            template: template,
            draftAssignments: _draftAssignments,
            inventoryItems: inventoryItems,
            ingredientParser: ingredientParser,
            localeCode: l10n.localeName,
          );
          final assignmentConversions = effectiveAssignmentConversions(
            template: template,
            draftAssignmentConversions: _draftAssignmentConversions,
            recipeIngredientAssignments: assignments,
            inventoryItems: inventoryItems,
            ingredientParser: ingredientParser,
          );
          final hasAssignmentChanges =
              !assignmentMapsEqual(
                template.recipeIngredientAssignments,
                assignments,
              ) ||
              !assignmentConversionMapsEqual(
                template.recipeIngredientAmountConversions,
                assignmentConversions,
              );

          return MealTemplateDetail(
            template: template,
            selectedPortions: selectedPortions,
            inventoryItems: inventoryItems,
            recipeIngredientAssignments: assignments,
            recipeIngredientAmountConversions: assignmentConversions,
            hasAssignmentChanges: hasAssignmentChanges,
            isCreatingMeal: _isCreatingMeal,
            isSavingTemplate: _isSavingTemplate,
            onDecreasePortions: selectedPortions > 1
                ? () {
                    setState(() {
                      _selectedPortions = selectedPortions - 1;
                    });
                  }
                : null,
            onIncreasePortions: () {
              setState(() {
                _selectedPortions = selectedPortions + 1;
              });
            },
            onAssignmentChanged:
                ({
                  required ingredient,
                  required inventoryItemIds,
                  required amountConversion,
                }) {
                  setState(() {
                    _draftAssignments = updatedAssignments(
                      assignments: assignments,
                      ingredient: ingredient,
                      inventoryItemIds: inventoryItemIds,
                    );
                    _draftAssignmentConversions = updatedAssignmentConversions(
                      conversions: assignmentConversions,
                      ingredient: ingredient,
                      amountConversion: amountConversion,
                    );
                  });
                },
            onCreateMealPressed: () => _createMealFromTemplate(
              context: context,
              template: template,
              selectedPortions: selectedPortions,
              recipeIngredientAssignments: assignments,
              recipeIngredientAmountConversions: assignmentConversions,
            ),
            onAddIngredientsToShoppingListPressed: () =>
                addTemplateIngredientsToShoppingList(
                  context: context,
                  ref: ref,
                  ingredientRows: buildIngredientRows(
                    template: template,
                    recipeIngredientAssignments: assignments,
                    recipeIngredientAmountConversions: assignmentConversions,
                    selectedPortions: selectedPortions,
                    ingredientParser: ingredientParser,
                  ),
                  inventoryItems: inventoryItems,
                ),
            onSaveTemplatePressed: hasAssignmentChanges
                ? () => _saveTemplateAssignments(
                    context: context,
                    templateId: template.id,
                    recipeIngredientAssignments: assignments,
                    recipeIngredientAmountConversions: assignmentConversions,
                  )
                : null,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: AppInsets.pageLarge,
              child: Text(l10n.preparedMealTemplateDetailLoadFailed),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createMealFromTemplate({
    required BuildContext context,
    required PreparedMeal template,
    required int selectedPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
  }) async {
    setState(() {
      _isCreatingMeal = true;
    });
    final result = await ref
        .read(preparedMealsControllerProvider.notifier)
        .createPreparedMealFromTemplate(
          template: template,
          totalPortions: selectedPortions,
          recipeIngredientAssignments: recipeIngredientAssignments,
          recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        );
    if (!mounted || !context.mounted) {
      return;
    }

    setState(() {
      _isCreatingMeal = false;
    });

    if (result.isSuccess && result.preparedMealId != null) {
      context.go(AppRoutes.homeInventory, extra: result.preparedMealId);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    showSnackBar(
      context,
      result.isSuccess
          ? l10n.preparedMealCreatedMessage
          : createMealFailureMessage(l10n, result.failureReason),
    );
  }

  Future<void> _saveTemplateAssignments({
    required BuildContext context,
    required String templateId,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
  }) async {
    setState(() {
      _isSavingTemplate = true;
    });
    final saved = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .updateRecipeIngredientAssignments(
          templateId: templateId,
          recipeIngredientAssignments: recipeIngredientAssignments,
          recipeIngredientAmountConversions: recipeIngredientAmountConversions,
        );
    if (!mounted || !context.mounted) {
      return;
    }

    setState(() {
      _isSavingTemplate = false;
      if (saved) {
        _draftAssignments = null;
        _draftAssignmentConversions = null;
      }
    });

    final l10n = AppLocalizations.of(context)!;
    showSnackBar(
      context,
      saved
          ? l10n.preparedMealTemplateUpdatedMessage
          : l10n.preparedMealTemplateDetailSaveFailedMessage,
    );
  }
}
