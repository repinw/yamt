import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_finalize_messages.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadGermanLocalizations() {
    return AppLocalizations.delegate.load(const Locale('de'));
  }

  test('maps every validation failure to localized text', () async {
    final l10n = await loadGermanLocalizations();

    expect(
      cookingFlowFinalizeValidationMessage(
        l10n,
        CookingFlowFinalizeValidationFailure.missingWeight,
      ),
      l10n.cookflowMissingWeight,
    );
    expect(
      cookingFlowFinalizeValidationMessage(
        l10n,
        CookingFlowFinalizeValidationFailure.missingGrossWeight,
      ),
      l10n.cookflowMissingWeight,
    );
    expect(
      cookingFlowFinalizeValidationMessage(
        l10n,
        CookingFlowFinalizeValidationFailure.invalidWeight,
      ),
      l10n.cookflowInvalidWeight,
    );
    expect(
      cookingFlowFinalizeValidationMessage(
        l10n,
        CookingFlowFinalizeValidationFailure.grossMustExceedTara,
      ),
      l10n.cookflowGrossMustExceedTara,
    );
    expect(
      cookingFlowFinalizeValidationMessage(
        l10n,
        CookingFlowFinalizeValidationFailure.ingredientContainerMissing,
      ),
      l10n.cookflowIngredientContainerMissing,
    );
    expect(
      cookingFlowFinalizeValidationMessage(
        l10n,
        CookingFlowFinalizeValidationFailure.containerMissingIngredients,
      ),
      l10n.cookflowContainerMissingIngredients,
    );
  });

  test('maps save failures to localized text', () async {
    final l10n = await loadGermanLocalizations();

    expect(
      cookingFlowFinalizeSaveFailureMessage(
        l10n: l10n,
        failure: CookingFlowFinalizeSaveFailure.templateNotFound,
        invalidInputMessage: null,
      ),
      l10n.cookflowTemplateNotFound,
    );
    expect(
      cookingFlowFinalizeSaveFailureMessage(
        l10n: l10n,
        failure: CookingFlowFinalizeSaveFailure.invalidInput,
        invalidInputMessage: 'Custom',
      ),
      'Custom',
    );
    expect(
      cookingFlowFinalizeSaveFailureMessage(
        l10n: l10n,
        failure: CookingFlowFinalizeSaveFailure.missingAssignments,
        invalidInputMessage: null,
      ),
      l10n.cookflowMissingAssignments,
    );
    expect(
      cookingFlowFinalizeSaveFailureMessage(
        l10n: l10n,
        failure: CookingFlowFinalizeSaveFailure.containerMissingIngredients,
        invalidInputMessage: null,
      ),
      l10n.cookflowContainerMissingIngredients,
    );
    expect(
      cookingFlowFinalizeSaveFailureMessage(
        l10n: l10n,
        failure: CookingFlowFinalizeSaveFailure.saveFailed,
        invalidInputMessage: null,
      ),
      l10n.cookflowSaveFailed,
    );
    expect(
      cookingFlowFinalizeSaveFailureMessage(
        l10n: l10n,
        failure: null,
        invalidInputMessage: null,
      ),
      l10n.cookflowSaveFailed,
    );
  });
}
