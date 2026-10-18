import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_template_from_items.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_edit_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_template_name_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Neue Vorlage" in the Kochbuch: picks Vorrat foods and saves them as a
/// cookbook template. The Vorrat stays as it is (#428).
abstract final class InventoryTemplateCreateFlow {
  const new _();

  /// Whether a tap waits for the Vorrat; only the wait is guarded, so a
  /// pick page dropped without a pop cannot block later taps.
  static var _isLoading = false;

  /// Opens the Vorrat in selection mode, then asks for the name, and saves
  /// the picked foods with all of their stock as a template. Closing either
  /// step saves nothing.
  static Future<void> create({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    // A second tap while the Vorrat loads would open a second pick page.
    if (_isLoading) {
      return;
    }
    // Held while it loads, so the Vorrat is not disposed before its list.
    final link = ref.listenManual(
      inventoryItemsControllerProvider.future,
      (_, _) {},
    );
    final List<InventoryItem> items;
    _isLoading = true;
    try {
      items = await link.read();
    } on Object catch (error, stackTrace) {
      log('The Vorrat did not load.', error: error, stackTrace: stackTrace);
      if (context.mounted) {
        _showFailure(
          context,
          AppLocalizations.of(context)!.inventoryLoadFailed,
        );
      }
      return;
    } finally {
      _isLoading = false;
      link.close();
    }
    if (!context.mounted) {
      return;
    }
    final picked = await showInventoryCombinePickPage(
      context,
      candidates: inventoryTemplateCandidates(items),
      emptyMessage: AppLocalizations.of(context)!.preparedMealTemplateNoFoods,
    );
    if (picked == null || picked.isEmpty || !context.mounted) {
      return;
    }
    final name = await PreparedMealTemplateNameSheet.show(
      context,
      initialName: picked.map((item) => item.name.trim()).join(', '),
    );
    if (name == null || !context.mounted) {
      return;
    }
    final meal = preparedMealTemplateFromItems(
      picked,
      name: name,
      now: ref.read(clockProvider)(),
    );
    if (meal == null) {
      _showFailure(
        context,
        AppLocalizations.of(context)!.preparedMealTemplateCreateFailed,
      );
      return;
    }
    final saved = await const InventoryPreparedMealEditCoordinator()
        .saveTemplate(
          context: context,
          ref: ref,
          meal: meal,
          messenger: ScaffoldMessenger.of(context),
        );
    if (!saved && context.mounted) {
      _showFailure(
        context,
        AppLocalizations.of(context)!.preparedMealTemplateCreateFailed,
      );
    }
  }

  static void _showFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showAppSnackBar(message, tone: AppSnackBarTone.error);
  }
}
