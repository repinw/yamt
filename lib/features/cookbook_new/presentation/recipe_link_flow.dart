import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_recipe_import_flow.dart';

/// Reads a recipe from a web page into the Kochbuch and opens the saved
/// recipe, which the AI then estimates in the background. A page that
/// cannot be read leads on to the editor of a new recipe that keeps the
/// link as its source and what the cook typed for the recipe, so the cook
/// pastes, scans, or types the recipe instead.
abstract final class RecipeLinkFlow {
  /// Asks for the link, then reads it.
  static Future<void> start(BuildContext context, WidgetRef ref) async {
    final result = await startRecipeTemplateImport(context, ref);
    if (context.mounted) {
      _finish(context, ref, result);
    }
  }

  /// Reads [link] without asking, such as a link another app shared.
  static Future<void> read(
    BuildContext context,
    WidgetRef ref,
    String link,
  ) async {
    final result = await importRecipeTemplate(context, ref, recipeUrl: link);
    if (context.mounted) {
      _finish(context, ref, result);
    }
  }

  /// Reads [link] again from the editor that keeps it; the review shows the
  /// cook's [name] and [portions] when given, and the saved recipe replaces
  /// the editor. Returns `false` when the page still cannot be read.
  static Future<bool> retry(
    BuildContext context,
    WidgetRef ref,
    String link, {
    required String name,
    required int? portions,
  }) async {
    final result = await importRecipeTemplate(
      context,
      ref,
      recipeUrl: link,
      name: name,
      portions: portions,
    );
    if (result is RecipeLinkSaved && context.mounted) {
      _estimate(ref, result.templateId);
      context.pushReplacement(AppRoutes.homeRecipePath(result.templateId));
    }
    return result is! RecipeLinkUnreadable;
  }

  static void _finish(
    BuildContext context,
    WidgetRef ref,
    RecipeLinkImport? result,
  ) {
    switch (result) {
      case RecipeLinkUnreadable(:final link, :final name, :final portions):
        unawaited(
          context.push(
            AppRoutes.homeRecipeNew,
            extra: RecipeEditorRouteArgs(
              recipeUrl: link,
              name: name,
              portions: portions,
            ),
          ),
        );
      case RecipeLinkSaved(:final templateId):
        // Going back from the recipe leads to where the import started.
        unawaited(context.push(AppRoutes.homeRecipePath(templateId)));
        _estimate(ref, templateId);
      case null:
        break;
    }
  }

  static void _estimate(WidgetRef ref, String recipeId) =>
      ref.read(recipeControllerProvider(recipeId).notifier).estimate();
}
