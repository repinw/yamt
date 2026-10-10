import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_lead.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The "Gefunden" step: every ingredient the Vorrat holds, taken from it
/// unless the cook puts it on the list or ignores it. A tap on a row calls
/// [onPick] to choose another Vorrat item.
class IngredientCheckFoundList extends StatelessWidget {
  /// Creates the step for [check].
  const new({
    required this.check,
    required this.onChoose,
    required this.onPick,
    super.key,
  });

  /// The recipe and the cook's choices.
  final IngredientCheckView check;

  /// Sets a choice.
  final IngredientCheckChoose onChoose;

  /// Opens the Vorrat picker for a line.
  final ValueChanged<RecipeIngredientLine> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final found = check.found;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.recipeCheckFoundKicker(found.length),
          title: l10n.recipeCheckFoundTitle,
          hint: l10n.recipeCheckFoundHint,
        ),
        for (final (index, line) in found.indexed)
          IngredientCheckRow(
            id: 'found-$index',
            lead: RecipeStockLead(item: line.row.stockItem),
            amount: ingredientAmountLabel(l10n, line.row.requirement),
            food: line.row.foodName,
            note: switch ((
              ingredientStockedLabel(l10n, line),
              line.shortfall,
            )) {
              (final stocked?, final shortfall?) when line.isPartial =>
                l10n.recipeCheckPartialNote(
                  stocked,
                  ingredientStockLabel(l10n, shortfall.amount, shortfall.unit),
                ),
              _ => null,
            },
            choice: check.draft.choiceOf(line),
            options: const [
              IngredientCheckChoice.use,
              IngredientCheckChoice.cart,
              IngredientCheckChoice.ignore,
            ],
            onChoose: (choice) => onChoose(line.ingredient, choice),
            onTap: () => onPick(line),
          ),
      ],
    );
  }
}
