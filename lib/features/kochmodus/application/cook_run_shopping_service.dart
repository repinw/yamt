import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';

part 'cook_run_shopping_service.g.dart';

/// The pause of the household's cook runs for the shopping.
@riverpod
CookRunShoppingService cookRunShoppingService(Ref ref) =>
    CookRunShoppingService(
      runs: ref.watch(cookRunRepositoryProvider),
      shopping: ref.watch(shoppingListNamesServiceProvider),
      parser: ref.watch(templateIngredientParserProvider),
    );

/// Pauses a cook run until its shopping is done.
class CookRunShoppingService {
  /// Creates the service.
  const new({
    required this._runs,
    required this._shopping,
    required this._parser,
  });

  final CookRunRepository _runs;
  final ShoppingListNamesService _shopping;
  final TemplateIngredientParser _parser;

  /// Puts the shopping lines of the run [runId] on the shopping list, then
  /// pauses the run ("Pausieren bis zum Einkauf"). Each line goes on the
  /// list as the page shows it (`cookLineLabel`): what this cooking needs,
  /// scaled to the portions, or the cook's own amount. When the list fails
  /// the run stays where it is and
  /// the error propagates. Throws a [CookRunGoneException] when the run is
  /// gone.
  Future<void> pause(String runId) async {
    await _runs.pending;
    final run = await _runs.load(runId);
    if (run == null) {
      throw CookRunGoneException(runId);
    }
    final names = [
      for (final line in run.lines)
        if (line.settlement is LineShopping)
          cookLineLabel(
            line,
            cookLineNeed(run, line, parseKochmodusLine(_parser, run, line)),
          ),
    ];
    if (names.isNotEmpty) {
      await _shopping.addMissing(names);
    }
    await _runs.mutate(runId, (run) => run.toStep(CookRunStep.paused));
  }
}
