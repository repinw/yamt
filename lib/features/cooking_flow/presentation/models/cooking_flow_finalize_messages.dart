import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Localized finalize validation message.
String cookingFlowFinalizeValidationMessage(
  AppLocalizations l10n,
  CookingFlowFinalizeValidationFailure failure,
) {
  return switch (failure) {
    CookingFlowFinalizeValidationFailure.missingWeight ||
    CookingFlowFinalizeValidationFailure.missingGrossWeight =>
      l10n.cookflowMissingWeight,
    CookingFlowFinalizeValidationFailure.invalidWeight =>
      l10n.cookflowInvalidWeight,
    CookingFlowFinalizeValidationFailure.grossMustExceedTara =>
      l10n.cookflowGrossMustExceedTara,
    CookingFlowFinalizeValidationFailure.ingredientContainerMissing =>
      l10n.cookflowIngredientContainerMissing,
    CookingFlowFinalizeValidationFailure.containerMissingIngredients =>
      l10n.cookflowContainerMissingIngredients,
  };
}

/// Localized finalize save failure message.
String cookingFlowFinalizeSaveFailureMessage({
  required AppLocalizations l10n,
  required CookingFlowFinalizeSaveFailure? failure,
  required String? invalidInputMessage,
}) {
  return switch (failure) {
    CookingFlowFinalizeSaveFailure.templateNotFound =>
      l10n.cookflowTemplateNotFound,
    CookingFlowFinalizeSaveFailure.invalidInput =>
      invalidInputMessage ?? l10n.cookflowSaveFailed,
    CookingFlowFinalizeSaveFailure.missingAssignments =>
      l10n.cookflowMissingAssignments,
    CookingFlowFinalizeSaveFailure.containerMissingIngredients =>
      l10n.cookflowContainerMissingIngredients,
    CookingFlowFinalizeSaveFailure.saveFailed ||
    null => l10n.cookflowSaveFailed,
  };
}
