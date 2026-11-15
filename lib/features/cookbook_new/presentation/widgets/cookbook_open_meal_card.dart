import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_running_card.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Framed card of a meal that is still in the pot or has open rows: its
/// picture, its name, where it is and how many rows are open, and "Weiter"
/// back to the pot or "Füllen" for a meal already in the Vorrat.
class CookbookOpenMealCard extends ConsumerWidget {
  /// Creates the card for [meal].
  const new({required this.meal, required this.onContinue, super.key});

  /// The meal in the pot or with open rows.
  final PreparedMeal meal;

  /// Opens the pot, or the meal to fill its open rows.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final since = CookbookRunningCard.timeOrDay(
      context,
      meal.createdAt,
      ref.watch(clockProvider)(),
    );
    final openRows = meal.pendingRecipeIngredients.length;
    final status = !meal.isInPot
        ? l10n.cookbookOpenMealRows(openRows)
        : openRows > 0
        ? l10n.cookbookInPotOpenRows(openRows, since)
        : l10n.cookbookInPotSince(since);

    return CookbookRunningCard(
      picture: CookbookMealPicture(meal: meal, size: AppGraphit.buttonHeight),
      name: meal.name,
      status: status,
      attention: true,
      action: meal.isInPot ? l10n.cookbookContinueAction : l10n.cookedFillRows,
      onAction: onContinue,
    );
  }
}
