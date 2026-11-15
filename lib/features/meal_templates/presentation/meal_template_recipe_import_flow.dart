import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/meal_templates/presentation/controllers/'
    'recipe_link_read_controller.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_template_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the dialog that shows while a recipe page is being read.
const recipeLinkReadingKey = ValueKey<String>('recipe-link-reading');

/// How a recipe link import ended, when it did not end with the cook
/// closing the sheet or the review.
sealed class RecipeLinkImport {
  const new();
}

/// The page at [link] could not be read.
final class RecipeLinkUnreadable extends RecipeLinkImport {
  /// Creates the result for [link], with what the cook typed for the recipe.
  const new(this.link, {this.name = '', this.portions});

  /// The link of the page.
  final String link;

  /// The name the cook typed; empty when there is none.
  final String name;

  /// The portion count the cook typed; `null` when there is none.
  final int? portions;
}

/// The review saved the recipe as the template [templateId].
final class RecipeLinkSaved extends RecipeLinkImport {
  /// Creates the result for [templateId].
  const new(this.templateId);

  /// The saved template.
  final String templateId;
}

/// Asks for a recipe link and imports it (see [importRecipeTemplate]).
/// Returns `null` also when the cook closes the sheet.
Future<RecipeLinkImport?> startRecipeTemplateImport(
  BuildContext context,
  WidgetRef ref,
) async {
  final draft = await showPreparedMealRecipeTemplateSheet(context);
  if (!context.mounted || draft == null) {
    return null;
  }
  return await importRecipeTemplate(
    context,
    ref,
    recipeUrl: draft.recipeUrl,
    name: draft.name,
    portions: draft.totalPortions,
  );
}

/// Reads the recipe at [recipeUrl] while a busy dialog shows, then opens its
/// review with the cook's [name] and [portions] when given. A page without
/// ingredient lines counts as unreadable, since nothing could be cooked from
/// it. Returns `null` when the cook leaves the review without saving.
Future<RecipeLinkImport?> importRecipeTemplate(
  BuildContext context,
  WidgetRef ref, {
  required String recipeUrl,
  String name = '',
  int? portions,
}) async {
  final importedRecipe = await _read(context, ref, recipeUrl);
  if (importedRecipe == null || importedRecipe.ingredients.isEmpty) {
    return RecipeLinkUnreadable(recipeUrl, name: name, portions: portions);
  }
  if (!context.mounted) {
    return null;
  }
  final templateId = await context.push<String>(
    AppRoutes.homeInventoryTemplateImportReview,
    extra: MealTemplateImportReviewArgs(
      importedRecipe: importedRecipe,
      preferredName: name,
      preferredPortions: portions,
    ),
  );
  return templateId == null ? null : RecipeLinkSaved(templateId);
}

/// The recipe at [recipeUrl], or `null` when its page cannot be read. Other
/// routes can land above the busy dialog while the page is read, such as a
/// second share or a tapped notification, so the dialog's own route goes.
Future<PreparedMealRecipeImport?> _read(
  BuildContext context,
  WidgetRef ref,
  String recipeUrl,
) async {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReadingDialog(label: l10n.recipeLinkReading),
  );
  navigator.push(route);
  try {
    return await ref
        .read(recipeLinkReadControllerProvider.notifier)
        .read(recipeUrl, localeName: l10n.localeName);
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}

/// Shows that a recipe page is being read. It stays until the reading
/// ends, which the importer limits in time.
class _ReadingDialog extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Center(
      child: Card(
        key: recipeLinkReadingKey,
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.lg,
            children: [
              const AppLoadingView(),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}
