import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_sentences.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';

part 'cooking_guide_view.g.dart';

/// One sentence of the Kochhelfer with the ingredients it names.
typedef CookingGuideSentence = ({
  RecipeSentence sentence,
  List<String> ingredients,
});

/// A recipe as the Kochhelfer reads it out: all of it first, then one
/// sentence at a time.
@immutable
class CookingGuide {
  /// Creates the guide for [view], where [justAddedKeys] are the line keys
  /// of the ingredients the cook added last.
  factory of(RecipeView view, {List<String> justAddedKeys = const <String>[]}) {
    final foods = [
      for (final line in view.lines)
        (label: line.label, words: ingredientFoodWords(line.ingredient)),
    ];
    final steps = view.recipe.recipeInstructions;
    return CookingGuide._(
      name: view.recipe.name,
      portions: view.portions,
      ingredients: [for (final food in foods) food.label],
      justAdded: [
        for (final line in view.lines)
          if (justAddedKeys.contains(line.key)) line.label,
      ],
      steps: steps,
      sentences: [
        for (final sentence in recipeSentences(steps))
          (
            sentence: sentence,
            ingredients: _named(ingredientFoodWords(sentence.text), foods),
          ),
      ],
    );
  }

  const new _({
    required this.name,
    required this.portions,
    required this.ingredients,
    required this.justAdded,
    required this.steps,
    required this.sentences,
  });

  static List<String> _named(
    Set<String> words,
    List<({String label, Set<String> words})> foods,
  ) => [
    for (final food in foods)
      if (food.words.any(words.contains)) food.label,
  ];

  /// The recipe's name.
  final String name;

  /// The portions to cook.
  final int portions;

  /// Every ingredient for [portions], as the recipe page names it.
  final List<String> ingredients;

  /// The ingredients the cook added last, which "Rückgängig" takes out.
  final List<String> justAdded;

  /// The recipe's steps.
  final List<String> steps;

  /// The sentences of [steps] in order.
  final List<CookingGuideSentence> sentences;
}

/// The Kochhelfer for the recipe [recipeId] as the recipe page cooks it:
/// with its portions and the cook's changes. `null` when the recipe is
/// gone.
@riverpod
AsyncValue<CookingGuide?> cookingGuide(
  Ref ref,
  String recipeId,
  String localeCode,
) {
  final justAddedKeys = ref.watch(
    recipeControllerProvider(recipeId).select((draft) => draft.justAdded),
  );
  return ref
      .watch(recipeViewProvider(recipeId, localeCode))
      .whenData(
        (view) => view == null
            ? null
            : CookingGuide.of(view, justAddedKeys: justAddedKeys),
      );
}
