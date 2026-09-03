import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Button that starts recipe import for prepared meal templates.
class MealTemplateRecipeImportButton extends ConsumerWidget {
  /// Creates a recipe import button.
  const MealTemplateRecipeImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.preparedMealTemplateAddRecipeAction,
      onPressed: () => unawaited(
        _createTemplateFromRecipe(
          context: context,
          importer: ref.read(preparedMealRecipeImporterProvider),
          localeName: l10n.localeName,
        ),
      ),
      icon: const Icon(Icons.add_link_rounded),
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
        name: 'MealTemplateRecipeImportButton',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!context.mounted) {
      return;
    }

    if (importedRecipe == null) {
      _showSnackBar(
        context,
        l10n.preparedMealTemplateRecipeImportFailedMessage,
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
