import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Adds a food from the catalog to the Vorrat selection (#654).
abstract final class InventorySelectionCatalogFlow {
  /// Opens the meal food search with [query] and adds the food the user
  /// picks to the selection. A food that cannot join the meal shows a hint.
  static Future<void> search({
    required BuildContext context,
    required WidgetRef ref,
    required String query,
  }) async {
    final pick = await context.push<InventoryMealFoodPick>(
      AppRoutes.homeFoodPickPath(query: query.isEmpty ? null : query),
    );
    if (pick == null || !context.mounted) {
      return;
    }
    final added = ref
        .read(preparedMealSelectionControllerProvider.notifier)
        .addCatalogFood(pick);
    if (!added) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppLocalizations.of(context)!.eatPageCombineNeedsNutrition,
        tone: AppSnackBarTone.error,
      );
    }
  }
}
