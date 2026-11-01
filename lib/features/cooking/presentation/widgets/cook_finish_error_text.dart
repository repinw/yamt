import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The message for a failed "In Vorrat" or its preview.
String cookFinishErrorText(AppLocalizations l10n, Object error) =>
    switch (error) {
      PreparedMealBuildException(
        reason: PreparedMealCreationFailureReason.missingNutrition,
      ) =>
        l10n.cookFinishMissingNutrition,
      PreparedMealBuildException(
        reason: PreparedMealCreationFailureReason.insufficientAmount,
      ) =>
        l10n.cookFinishTooLittle,
      PreparedMealBuildException(
        reason: PreparedMealCreationFailureReason.itemUnavailable,
      ) =>
        l10n.cookFinishItemGone,
      PreparedMealBuildException(
        reason: PreparedMealCreationFailureReason.invalidInput,
      ) =>
        l10n.cookFinishNothingTaken,
      _ => l10n.cookFinishFailed,
    };
