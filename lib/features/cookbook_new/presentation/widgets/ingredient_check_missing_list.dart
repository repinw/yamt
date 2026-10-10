import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_lead.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Starts "Hab ich" for a line, or for its missing part when [rest].
typedef IngredientCheckHave = void Function(
  RecipeIngredientLine line, {
  required bool rest,
});

/// The "Fehlt" step: every ingredient the Vorrat lacks and the missing part
/// of the partly stocked ones, on the list unless the cook has it or ignores
/// it.
class IngredientCheckMissingList extends StatelessWidget {
  /// Creates the step for [check].
  const new({
    required this.check,
    required this.onChoose,
    required this.onHave,
    super.key,
  });

  /// The recipe and the cook's choices.
  final IngredientCheckView check;

  /// Sets a choice.
  final IngredientCheckChoose onChoose;

  /// Starts "Hab ich".
  final IngredientCheckHave onHave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = check.draft;
    List<IngredientCheckChoice> options(RecipeIngredientLine line) => [
      IngredientCheckChoice.cart,
      // Only an amount can come from the Vorrat.
      if (line.row.requirement != null) IngredientCheckChoice.have,
      IngredientCheckChoice.ignore,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.recipeCheckMissingKicker(check.missingCount),
          title: l10n.recipeCheckMissingTitle,
          hint: l10n.recipeCheckMissingHint,
        ),
        for (final (index, line) in check.missing.indexed)
          IngredientCheckRow(
            id: 'missing-$index',
            lead: const RecipeStockLead(),
            amount: ingredientAmountLabel(l10n, line.row.requirement),
            food: line.row.foodName,
            choice: draft.choiceOf(line),
            options: options(line),
            onChoose: (choice) => onChoose(line.key, choice),
            onHave: () => onHave(line, rest: false),
          ),
        for (final (index, line) in check.rests.indexed)
          if ((ingredientStockedLabel(l10n, line), line.shortfall) case (
            final stocked?,
            final shortfall?,
          ))
            IngredientCheckRow(
              id: 'rest-$index',
              lead: const RecipeStockLead(isRest: true),
              amount: ingredientStockLabel(
                l10n,
                shortfall.amount,
                shortfall.unit,
              ),
              food: line.row.foodName,
              note: l10n.recipeCheckRest(stocked),
              choice: draft.restChoiceOf(line),
              options: options(line),
              onChoose: (choice) => onChoose(line.key, choice, rest: true),
              onHave: () => onHave(line, rest: true),
            ),
      ],
    );
  }
}
