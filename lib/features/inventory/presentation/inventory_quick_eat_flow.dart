import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_application.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What an eat flow needs to log food after its sheet has closed.
class InventoryQuickEatFlowScope {
  /// Creates the scope.
  const new({
    required this.container,
    required this.actions,
    required this.messenger,
    required this.l10n,
  });

  /// Container of the page that opened the sheet.
  final ProviderContainer container;

  /// Actions that stage and log the food.
  final InventoryQuickEatActions actions;

  /// Messenger for the result snack bars.
  final ScaffoldMessengerState messenger;

  /// Texts of the snack bars.
  final AppLocalizations l10n;
}

/// Runs [body] with the quick eat actions of [context] and keeps them alive
/// until [body] completes.
Future<T> runInventoryQuickEatFlow<T>(
  BuildContext context,
  Future<T> Function(InventoryQuickEatFlowScope scope) body,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final subscription = container.listen(
    inventoryQuickEatActionsProvider,
    (_, _) {},
  );
  try {
    return await body(
      InventoryQuickEatFlowScope(
        container: container,
        actions: container.read(inventoryQuickEatActionsProvider),
        messenger: ScaffoldMessenger.of(context),
        l10n: AppLocalizations.of(context)!,
      ),
    );
  } finally {
    subscription.close();
  }
}
