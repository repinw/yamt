import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// Whether [run] assigned each recipe line it does not ignore, or nothing
/// while no run exists or no line is assigned yet.
List<bool> _assignedLines(CookRun? run) {
  final lines = [
    for (final line in run?.lines ?? const <CookRunLine>[])
      if (line.origin == CookLineOrigin.recipe &&
          line.settlement is! LineIgnored)
        line.settlement is LineAssigned,
  ];
  return lines.contains(true) ? lines : const [];
}

/// A saved Vorlage or recipe with the stock state of each of its foods.
@immutable
class CookbookEntry {
  /// Creates the entry for [meal] with one stock flag per food.
  const new({required this.meal, required this.inStock});

  /// The saved template.
  final PreparedMeal meal;

  /// Whether the Vorrat holds each food, in the order of the foods. For a
  /// recipe, whether its cook run assigned each line it does not ignore;
  /// empty until the cook assigned the first line by hand.
  final List<bool> inStock;

  /// Number of foods that the Vorrat does not hold; for a recipe, of the
  /// lines its cook run has not assigned.
  int get missingCount => inStock.where((isInStock) => !isInStock).length;
}

/// A cook run of the household as "Läuft" lists it.
@immutable
class CookbookRun {
  /// Creates the row of [run].
  const new({
    required this.run,
    required this.startedByMe,
    required this.nextTimer,
  });

  /// The running cook run.
  final CookRun run;

  /// Whether the signed-in member started it.
  final bool startedByMe;

  /// The running timer of the run that rings first, `null` while none
  /// runs.
  final CookTimer? nextTimer;
}

/// Everything the Kochbuch shows: running cook runs, meals still in the pot,
/// Vorlagen combined from the Vorrat, and recipes.
@immutable
class CookbookOverview {
  /// Creates the overview.
  const new({
    required this.runs,
    required this.openMeals,
    required this.templates,
    required this.recipes,
  });

  /// Sorts saved [savedTemplates] into Vorlagen and recipes, picks the
  /// meals in [meals] that are still in the pot or have open rows, and lists
  /// the household's cook runs [runs] in their order. [userId] is the
  /// signed-in member; [now] tells the timers still running from the rung.
  ///
  /// A template with recipe ingredients is a recipe; one without is a Vorlage
  /// combined from Vorrat foods. [isInStock] tells whether the Vorrat holds a
  /// food of a Vorlage by its name. A recipe is never matched against the
  /// Vorrat: its lines show what its cook run assigned by hand.
  factory fromMeals({
    required List<CookRun> runs,
    required String? userId,
    required DateTime now,
    required List<PreparedMeal> savedTemplates,
    required List<PreparedMeal> meals,
    required bool Function(String food) isInStock,
  }) {
    final templates = <CookbookEntry>[];
    final recipes = <CookbookEntry>[];
    for (final template in savedTemplates) {
      if (template.recipeIngredients.isEmpty) {
        templates.add(
          CookbookEntry(
            meal: template,
            inStock: [
              for (final component in template.components)
                isInStock(component.name),
            ],
          ),
        );
      } else {
        recipes.add(
          CookbookEntry(
            meal: template,
            inStock: _assignedLines(
              runs.firstWhereOrNull((run) => run.recipeId == template.id),
            ),
          ),
        );
      }
    }
    final openMeals = meals.where((meal) => meal.isOpen).toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return CookbookOverview(
      runs: List.unmodifiable([
        for (final run in runs)
          CookbookRun(
            run: run,
            startedByMe: run.startedBy == userId,
            nextTimer: minBy(
              run.timers.where((timer) => timer.endsAt.isAfter(now)),
              (timer) => timer.endsAt,
            ),
          ),
      ]),
      openMeals: List.unmodifiable(openMeals),
      templates: List.unmodifiable(templates),
      recipes: List.unmodifiable(recipes),
    );
  }

  /// The household's cook runs, newest first.
  final List<CookbookRun> runs;

  /// Meals in the Vorrat that are still in the pot or have open rows, newest
  /// first.
  final List<PreparedMeal> openMeals;

  /// Vorlagen combined from Vorrat foods.
  final List<CookbookEntry> templates;

  /// Recipes from a link, a photo, or the AI.
  final List<CookbookEntry> recipes;
}
