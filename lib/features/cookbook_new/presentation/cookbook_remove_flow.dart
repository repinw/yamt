import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Removes a Vorlage or recipe from the Kochbuch and offers an undo.
///
/// The undo may run after the page closed, so the flow reads the controller
/// from the page's container, never through the page's `context`.
abstract final class CookbookRemoveFlow {
  const new _();

  /// Key of the snack bar that says the template is gone.
  static const snackBarKey = ValueKey<String>('cookbook-removed');

  /// Removes [template] and shows "… entfernt" with "Rückgängig", which saves
  /// it back with the same id and content. With [closePage], the page of
  /// [context] closes first, so the snack bar shows on the Kochbuch, and the
  /// template goes once the page is out of sight.
  /// Returns whether the template is gone; a failure says so.
  static Future<bool> remove(
    BuildContext context, {
    required PreparedMeal template,
    bool closePage = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    CookbookController controller() =>
        container.read(cookbookControllerProvider(l10n.localeName).notifier);
    if (closePage) {
      // A second tap while the page closes removes nothing more.
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        return false;
      }
      context.pop();
      // Removing while the page still slides out would show it as gone.
      await route.completed;
    }

    final removed = await controller().remove(template);
    if (!messenger.mounted) {
      return removed;
    }
    if (!removed) {
      messenger.showAppSnackBar(
        l10n.cookbookRemoveFailed(template.name),
        tone: AppSnackBarTone.error,
      );
      return false;
    }
    messenger.showAppSnackBar(
      l10n.cookbookRemovedMessage(template.name),
      key: snackBarKey,
      // Read again: the controller of the remove may be gone by now.
      onUndo: () => controller().restore(template),
    );
    return true;
  }
}
