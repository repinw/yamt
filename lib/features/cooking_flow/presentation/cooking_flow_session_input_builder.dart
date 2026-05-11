import 'package:flutter/widgets.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_controller.dart';

/// Builds session input from page-owned controllers.
CookingFlowWizardSessionInput buildCookingFlowWizardSessionInput({
  required String templateId,
  required CookingFlowStorageContainerController storageController,
  required TextEditingController adjustmentController,
  required Map<String, String> ingredientContainerAssignments,
}) {
  return CookingFlowWizardSessionInput(
    templateId: templateId,
    taraText: storageController.taraController.text.trim(),
    taraUtensilId: storageController.selectedTaraUtensilId,
    adjustmentInputText: adjustmentController.text.trim(),
    grossWeightText: storageController.grossWeightController.text.trim(),
    storageContainers: storageController.sessionDrafts(),
    ingredientContainerAssignments: ingredientContainerAssignments,
  );
}
