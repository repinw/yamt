import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/features/inventory/provider/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/prepared_meals/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/meal_templates/application/'
    'recipe_source_host.dart';
import 'package:yamt/features/shoppinglist/provider/'
    'shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'meal_template_detail_content.dart';
part 'meal_template_detail_ingredient_card.dart';
part 'meal_template_detail_actions.dart';
part 'meal_template_detail_helpers.dart';

class MealTemplateDetailPage extends ConsumerStatefulWidget {
  const MealTemplateDetailPage({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<MealTemplateDetailPage> createState() =>
      _MealTemplateDetailPageState();
}

class _MealTemplateDetailPageState
    extends ConsumerState<MealTemplateDetailPage> {
  int? _selectedPortions;
  Map<String, List<String>>? _draftAssignments;
  var _isCreatingMeal = false;
  var _isSavingTemplate = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(preparedMealTemplatesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preparedMealTemplateDetailTitle)),
      body: templatesAsync.when(
        data: (templates) {
          final template = _findTemplate(
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
              _selectedPortions ?? _defaultPortions(template.totalPortions);
          final assignments = _effectiveAssignments(
            template: template,
            draftAssignments: _draftAssignments,
          );
          final hasAssignmentChanges = !_assignmentMapsEqual(
            template.recipeIngredientAssignments,
            assignments,
          );

          return _MealTemplateDetailContent(
            template: template,
            selectedPortions: selectedPortions,
            recipeIngredientAssignments: assignments,
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
                  required String ingredient,
                  required List<String> inventoryItemIds,
                }) {
                  setState(() {
                    _draftAssignments = _updatedAssignments(
                      assignments: assignments,
                      ingredient: ingredient,
                      inventoryItemIds: inventoryItemIds,
                    );
                  });
                },
            onCreateMealPressed: () => _createMealFromTemplate(
              context: context,
              template: template,
              selectedPortions: selectedPortions,
              recipeIngredientAssignments: assignments,
            ),
            onAddIngredientsToShoppingListPressed: () =>
                _addTemplateIngredientsToShoppingList(
                  context: context,
                  ref: ref,
                  ingredientRows: _buildIngredientRows(
                    template: template,
                    recipeIngredientAssignments: assignments,
                    selectedPortions: selectedPortions,
                  ),
                ),
            onSaveTemplatePressed: hasAssignmentChanges
                ? () => _saveTemplateAssignments(
                    context: context,
                    templateId: template.id,
                    recipeIngredientAssignments: assignments,
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
    _showSnackBar(
      context,
      result.isSuccess
          ? l10n.preparedMealCreatedMessage
          : _createMealFailureMessage(l10n, result.failureReason),
    );
  }

  Future<void> _saveTemplateAssignments({
    required BuildContext context,
    required String templateId,
    required Map<String, List<String>> recipeIngredientAssignments,
  }) async {
    setState(() {
      _isSavingTemplate = true;
    });
    final saved = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .updateRecipeIngredientAssignments(
          templateId: templateId,
          recipeIngredientAssignments: recipeIngredientAssignments,
        );
    if (!mounted || !context.mounted) {
      return;
    }

    setState(() {
      _isSavingTemplate = false;
      if (saved) {
        _draftAssignments = null;
      }
    });

    final l10n = AppLocalizations.of(context)!;
    _showSnackBar(
      context,
      saved
          ? l10n.preparedMealTemplateUpdatedMessage
          : l10n.preparedMealTemplateDetailSaveFailedMessage,
    );
  }
}
