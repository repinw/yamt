import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_template_lookup.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_cooking_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_finalize_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_preparation_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_success_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_page.dart';
import 'package:yamt/features/cooking_flow/presentation/models/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_page_body/cooking_flow_page_status.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Builds the active cookflow step body.
class CookingFlowPageBody extends StatelessWidget {
  /// Creates cookflow body.
  const new({
    required this.isRestoringSession,
    required this.templatesAsync,
    required this.wizardState,
    required this.templateId,
    required this.targetPortions,
    required this.introDraft,
    required this.introShoppingBaselineInventoryItemIds,
    required this.introResetSignal,
    required this.storageContainers,
    required this.containerPortions,
    required this.adjustmentController,
    required this.adjustments,
    required this.summaryIngredients,
    required this.inventoryItems,
    required this.ingredientContainerAssignments,
    required this.isWeightValid,
    required this.buildNutritionPreview,
    required this.splitIntoPortions,
    required this.validationMessage,
    required this.finalPortionCount,
    required this.savedMealName,
    required this.onTemplateResolved,
    required this.onInventoryPressed,
    required this.onTargetPortionsChanged,
    required this.onRestartPressed,
    required this.onShoppingLabelsResolved,
    required this.onSelectionStateChanged,
    required this.onContainerChanged,
    required this.onContainerTaraUtensilSelected,
    required this.onAddContainerPressed,
    required this.onRemoveContainerPressed,
    required this.onOpenKitchenUtensilsPressed,
    required this.onAddAdjustmentPressed,
    required this.onRemoveAdjustmentPressed,
    required this.onSummaryAmountChanged,
    required this.onRemoveSummaryIngredient,
    required this.onAddIngredientSourceSelected,
    required this.onAdjustmentSourceSelected,
    required this.onIngredientContainerChanged,
    required this.onSplitIntoPortionsChanged,
    required this.onFinalPortionCountChanged,
    super.key,
  });

  /// Whether session restore is still loading.
  final bool isRestoringSession;

  /// Template load state.
  final AsyncValue<List<PreparedMeal>> templatesAsync;

  /// Current wizard state.
  final CookingFlowWizardState wizardState;

  /// Active template id.
  final String templateId;

  /// Scaled recipe portion count.
  final double targetPortions;

  /// Restored intro draft.
  final CookingFlowIntroDraft? introDraft;

  /// Inventory ids present before shopping detour.
  final List<String> introShoppingBaselineInventoryItemIds;

  /// Signal used to reset intro local UI.
  final int introResetSignal;

  /// Current storage container views.
  final List<CookingFlowStorageContainerView> storageContainers;

  /// Portions saved per storage container.
  final List<int> containerPortions;

  /// Controller for on-the-fly input.
  final TextEditingController adjustmentController;

  /// On-the-fly adjustment list.
  final List<String> adjustments;

  /// Current summary ingredients.
  final List<CookingFlowSummaryIngredientDraft> summaryIngredients;

  /// Current inventory items.
  final List<InventoryItem> inventoryItems;

  /// Ingredient row to container id map.
  final Map<String, String> ingredientContainerAssignments;

  /// Whether finalize weight input is valid.
  final bool isWeightValid;

  /// Builds nutrition preview for finalize step.
  final CookingFlowNutritionPreview Function({
    required PreparedMeal template,
    required List<InventoryItem> inventoryItems,
  })
  buildNutritionPreview;

  /// Whether final meal should be split into portions.
  final bool splitIntoPortions;

  /// Current finalize validation message.
  final String? validationMessage;

  /// Final portion count.
  final double finalPortionCount;

  /// Saved meal display name.
  final String savedMealName;

  /// Called when template is available.
  final ValueChanged<PreparedMeal> onTemplateResolved;

  /// Opens saved meal in inventory.
  final VoidCallback onInventoryPressed;

  /// Updates recipe target portions.
  final ValueChanged<double> onTargetPortionsChanged;

  /// Restarts the cookflow session.
  final Future<void> Function() onRestartPressed;

  /// Resolves intro shopping labels.
  final Future<void> Function(List<String> labels) onShoppingLabelsResolved;

  /// Updates intro CTA state.
  final ValueChanged<CookingFlowIntroSelectionState> onSelectionStateChanged;

  /// Handles storage container text change.
  final ValueChanged<String> onContainerChanged;

  /// Handles utensil selection for one container.
  final void Function(String containerId, KitchenUtensil utensil)
  onContainerTaraUtensilSelected;

  /// Adds storage container.
  final VoidCallback onAddContainerPressed;

  /// Removes storage container.
  final ValueChanged<String> onRemoveContainerPressed;

  /// Opens utensil library.
  final VoidCallback onOpenKitchenUtensilsPressed;

  /// Adds on-the-fly adjustment.
  final VoidCallback onAddAdjustmentPressed;

  /// Removes on-the-fly adjustment.
  final ValueChanged<int> onRemoveAdjustmentPressed;

  /// Updates summary ingredient amount.
  final void Function(int index, String value) onSummaryAmountChanged;

  /// Removes summary ingredient.
  final ValueChanged<int> onRemoveSummaryIngredient;

  /// Starts add ingredient flow.
  final ValueChanged<CookingFlowSummaryIngredientAddSource>
  onAddIngredientSourceSelected;

  /// Starts adjustment resolution flow.
  final void Function(int index, CookingFlowSummaryIngredientAddSource source)
  onAdjustmentSourceSelected;

  /// Updates ingredient container assignment.
  final void Function(String rowKey, String containerId)
  onIngredientContainerChanged;

  /// Updates split into portions flag.
  final ValueChanged<bool> onSplitIntoPortionsChanged;

  /// Updates final portion count.
  final ValueChanged<double> onFinalPortionCountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isRestoringSession) {
      return const CookingFlowPageStatus();
    }

    if (wizardState.step == CookingFlowStep.success) {
      return CookingFlowSuccessPage(
        mealName: savedMealName,
        onInventoryPressed: onInventoryPressed,
      );
    }

    return templatesAsync.when(
      data: (templates) {
        final template = findCookingFlowTemplate(templates, templateId);
        if (template == null) {
          return CookingFlowPageStatus(message: l10n.cookflowTemplateNotFound);
        }

        onTemplateResolved(template);

        return switch (wizardState.step) {
          CookingFlowStep.start => CookingFlowIntroPage(
            template: template,
            targetPortions: targetPortions,
            initialDraft: introDraft,
            shoppingBaselineInventoryItemIds:
                introShoppingBaselineInventoryItemIds,
            resetSignal: introResetSignal,
            onTargetPortionsChanged: onTargetPortionsChanged,
            onRestartPressed: onRestartPressed,
            onShoppingLabelsResolved: onShoppingLabelsResolved,
            onSelectionStateChanged: onSelectionStateChanged,
          ),
          CookingFlowStep.preparation => CookingFlowPreparationPage(
            storageContainers: storageContainers,
            onContainerChanged: onContainerChanged,
            onContainerTaraUtensilSelected: onContainerTaraUtensilSelected,
            onAddContainerPressed: onAddContainerPressed,
            onRemoveContainerPressed: onRemoveContainerPressed,
            onOpenKitchenUtensilsPressed: onOpenKitchenUtensilsPressed,
          ),
          CookingFlowStep.cooking => CookingFlowCookingPage(
            template: template,
            introDraft: introDraft,
            targetPortions: wizardState.targetRecipePortions,
            adjustmentController: adjustmentController,
            adjustments: adjustments,
            onAddPressed: onAddAdjustmentPressed,
            onRemovePressed: onRemoveAdjustmentPressed,
          ),
          CookingFlowStep.summary => CookingFlowSummaryPage(
            ingredients: summaryIngredients,
            inventoryItems: inventoryItems,
            adjustments: adjustments,
            onAmountChanged: onSummaryAmountChanged,
            onRemoveIngredient: onRemoveSummaryIngredient,
            onAddIngredientSourceSelected: onAddIngredientSourceSelected,
            onAdjustmentSourceSelected: onAdjustmentSourceSelected,
            storageContainers: storageContainers,
            ingredientContainerAssignments: ingredientContainerAssignments,
            onIngredientContainerChanged: onIngredientContainerChanged,
          ),
          CookingFlowStep.finalize => CookingFlowFinalizePage(
            storageContainers: storageContainers,
            containerPortions: containerPortions,
            isWeightValid: isWeightValid,
            nutritionPreview: buildNutritionPreview(
              template: template,
              inventoryItems: inventoryItems,
            ),
            splitIntoPortions: splitIntoPortions,
            validationMessage: validationMessage,
            portionCount: finalPortionCount,
            onContainerChanged: onContainerChanged,
            onSplitIntoPortionsChanged: onSplitIntoPortionsChanged,
            onPortionCountChanged: onFinalPortionCountChanged,
          ),
          CookingFlowStep.success => const SizedBox.shrink(),
        };
      },
      loading: () => const CookingFlowPageStatus(),
      error: (error, stackTrace) =>
          CookingFlowPageStatus(message: l10n.cookflowLoadFailed),
    );
  }
}
