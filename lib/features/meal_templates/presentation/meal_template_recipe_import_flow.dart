import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Starts the recipe import for a new prepared meal template: asks for the
/// recipe link, imports it, and opens the import review.
void startRecipeTemplateImport(BuildContext context, WidgetRef ref) {
  unawaited(
    _createTemplateFromRecipe(
      context: context,
      importer: ref.read(preparedMealRecipeImporterProvider),
      localeName: AppLocalizations.of(context)!.localeName,
    ),
  );
}

Future<void> _createTemplateFromRecipe({
  required BuildContext context,
  required PreparedMealRecipeImporter importer,
  required String localeName,
}) async {
  final draft = await showPreparedMealRecipeTemplateSheet(context);
  if (!context.mounted || draft == null) {
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  PreparedMealRecipeImport? importedRecipe;
  try {
    importedRecipe = await importer.importRecipe(
      draft.recipeUrl,
      localeName: localeName,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Failed to import recipe from ${draft.recipeUrl}',
      name: 'MealTemplateRecipeImportFlow',
      error: error,
      stackTrace: stackTrace,
    );
  }
  if (!context.mounted) {
    return;
  }

  if (importedRecipe == null) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.preparedMealTemplateRecipeImportFailedMessage,
      tone: AppSnackBarTone.error,
    );
    return;
  }

  unawaited(
    context.push(
      AppRoutes.homeInventoryTemplateImportReview,
      extra: MealTemplateImportReviewArgs(
        importedRecipe: importedRecipe,
        preferredName: draft.name,
        preferredPortions: draft.totalPortions,
      ),
    ),
  );
}
