import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_idea_sheet.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Rezeptidee" from the "Neu" menu: the AI chef puts a recipe idea
/// together, the window shows it as a recipe, and "Im Kochbuch speichern"
/// adds it with an undo.
abstract final class RecipeIdeaFlow {
  const new _();

  /// Key of the snack bar that says the idea is saved.
  static const savedSnackBarKey = ValueKey<String>('recipe-idea-saved');

  /// Key of the snack bar that says saving the idea failed.
  static const saveFailedSnackBarKey = ValueKey<String>(
    'recipe-idea-save-failed',
  );

  /// Asks for a recipe idea, shows it, and says how saving went.
  ///
  /// The result comes from the save itself, not from how the window closed:
  /// a cook who closes the window while it saves still gets the snack bar,
  /// or the error when it fails then. The undo may run after the Kochbuch
  /// closed, so it reads the controller from the page's container, never
  /// through its `context`.
  static Future<void> start(BuildContext context) async {
    final idea = await AiChefSheet.show(context);
    if (idea == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    Future<PreparedMeal?>? saving;
    await RecipeIdeaSheet.show(
      context,
      idea: idea,
      onSaving: (value) => saving = value,
    );
    final pending = saving;
    if (pending == null) return;
    final saved = await pending;
    if (saved == null) {
      messenger.showAppSnackBar(
        l10n.aiChefSaveError,
        tone: AppSnackBarTone.error,
        key: saveFailedSnackBarKey,
      );
      return;
    }
    messenger.showAppSnackBar(
      l10n.aiChefSaveSuccess,
      key: savedSnackBarKey,
      onUndo: () => container
          .read(cookbookControllerProvider(l10n.localeName).notifier)
          .remove(saved),
    );
  }
}
