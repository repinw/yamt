import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_schedule_dialog/shopping_list_schedule_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Changes to one shopping entry that start in a widget: each runs the
/// controller action and shows a message when the list could not be saved.
abstract final class ShoppingListEntryFlow {
  /// Saves or drops [item] as a favorite.
  static Future<void> toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
  ) => run(context, ref, (controller) => controller.toggleFavorite(item.id));

  /// Asks for the schedule of [item] and saves it.
  static Future<void> editSchedule(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
  ) async {
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final input = await showShoppingScheduleDialog(context, item);
    if (input == null || !context.mounted) return;
    await _report(
      context,
      controller.setSchedule(
        item.id,
        days: input.days,
        quantity: input.quantity,
        firstDue: input.firstDue,
      ),
    );
  }

  /// Runs [action] on the list controller and returns whether it saved. The
  /// message for a failed save still shows when the widget behind [context]
  /// is gone by then.
  static Future<bool> run(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function(ShoppingListController controller) action,
  ) => _report(
    context,
    action(ref.read(shoppingListControllerProvider.notifier)),
  );

  static Future<bool> _report(BuildContext context, Future<bool> saving) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.shoppingListSaveFailed;
    final saved = await saving;
    if (!saved) {
      messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
    }
    return saved;
  }
}
