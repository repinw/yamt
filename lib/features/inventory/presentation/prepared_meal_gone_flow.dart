import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Closes a Vorrat meal page when its meal is gone.
abstract final class PreparedMealGoneFlow {
  /// Closes the page of the meal [mealId] and says so when the meal leaves
  /// the Vorrat after the page saw it, for example when someone in the
  /// household ate it up or unbundled it. Call it from the page's `build`.
  static void closeWhenGone(
    WidgetRef ref,
    BuildContext context,
    String mealId,
  ) {
    ref.listen(livePreparedMealProvider(mealId), (previous, next) {
      if (previous?.value != null && next.hasValue && next.value == null) {
        close(context);
      }
    });
  }

  /// Closes the page of a meal that is gone, together with every sheet or
  /// dialog open on top of it, and shows "Mahlzeit nicht mehr im Vorrat".
  /// Does nothing when the page is already closing, for example because a
  /// meal page below it closed it first.
  static void close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) {
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.preparedMealGone;
    navigator
      ..popUntil((top) => top == route)
      ..pop();
    messenger
      ..hideCurrentSnackBar()
      ..showAppSnackBar(message);
  }
}
