import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_plan_needs_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks whether the needs go on the shopping list, each one tickable, and adds
/// the ticked ones. Nothing goes on the list without the tap.
abstract final class ShoppingPlanNeedsFlow {
  /// Shows the question for [needs]; does nothing when they are empty.
  /// Adds nothing once [isCancelled] says the plan behind them is gone.
  /// With [offerNeverAsk], the question offers "Nicht mehr fragen"; returns
  /// whether the user picked it.
  static Future<bool> offer(
    BuildContext context,
    List<ShoppingPlanNeed> needs, {
    required bool Function() isCancelled,
    bool offerNeverAsk = false,
  }) async {
    if (needs.isEmpty) {
      return false;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final answer = await showDialog<ShoppingPlanNeedsAnswer>(
      context: context,
      builder: (_) =>
          ShoppingPlanNeedsDialog(needs: needs, offerNeverAsk: offerNeverAsk),
    );
    final picked = answer?.picked ?? const [];
    if (picked.isEmpty || isCancelled()) {
      return answer?.neverAsk ?? false;
    }
    // Keeps the list alive while the adds run, also when no page shows it.
    final list = container.listen(shoppingListControllerProvider, (_, _) {});
    var saved = true;
    try {
      for (final need in picked) {
        saved &= await container
            .read(shoppingListControllerProvider.notifier)
            .addItem(name: need.name, brand: need.brand);
      }
    } finally {
      list.close();
    }
    if (!saved) {
      messenger.showAppSnackBar(
        l10n.shoppingListAddFailedError,
        tone: AppSnackBarTone.error,
      );
    }
    return false;
  }
}
