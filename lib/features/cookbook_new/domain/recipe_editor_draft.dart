import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:yamt/features/cookbook_new/domain/pasted_recipe_text.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// The two lists of lines in a recipe.
enum RecipeEditorSection {
  /// The ingredient lines.
  ingredients,

  /// The preparation steps.
  steps,
}

/// A new recipe, or the changes to a saved one, as the recipe editor holds
/// them.
@immutable
class RecipeEditorDraft {
  /// Creates an empty draft for two portions.
  const new({
    this.original,
    this.recipeUrl,
    this.name = '',
    this.portions = 2,
    this.ingredients = const [],
    this.steps = const [],
    this.photo,
  });

  /// The draft of the saved [recipe], with its lines.
  factory fromRecipe(PreparedMeal recipe) => RecipeEditorDraft(
    original: recipe,
    name: recipe.name,
    portions: recipe.totalPortions < 1 ? 1 : recipe.totalPortions,
    ingredients: [
      for (final line in recipe.recipeIngredients)
        RecipeEditorLine(
          text: line,
          saved: line,
          weight: recipe.recipeLineWeights[line],
        ),
    ],
    steps: [
      for (final step in recipe.recipeInstructions)
        RecipeEditorLine(text: step),
    ],
  );

  /// The saved recipe; `null` for a new one.
  final PreparedMeal? original;

  /// The link of the page a new recipe comes from.
  final String? recipeUrl;

  /// The name as typed.
  final String name;

  /// The portion count, at least one.
  final int portions;

  /// The ingredient lines.
  final List<RecipeEditorLine> ingredients;

  /// The preparation steps.
  final List<RecipeEditorLine> steps;

  /// The photo picked in the editor, which replaces the saved one.
  final Uint8List? photo;

  /// The lines of [section].
  List<RecipeEditorLine> linesOf(RecipeEditorSection section) =>
      switch (section) {
        .ingredients => ingredients,
        .steps => steps,
      };

  /// Whether the draft has neither an ingredient nor a step.
  bool get isEmpty => ingredients.isEmpty && steps.isEmpty;

  /// Whether the draft has a name and an ingredient.
  bool get canSave => name.trim().isNotEmpty && ingredients.isNotEmpty;

  /// Whether closing the editor would lose something: the name, portions,
  /// lines with their weights, or a picked photo differ from where the draft
  /// started, an empty draft or the saved recipe. The link a new recipe keeps
  /// does not count, since no one typed it.
  bool get hasChanges {
    final start = switch (original) {
      final recipe? => RecipeEditorDraft.fromRecipe(recipe),
      null => const RecipeEditorDraft(),
    };
    return photo != null ||
        name.trim() != start.name.trim() ||
        portions != start.portions ||
        !_sameLines(ingredients, start.ingredients) ||
        !_sameLines(steps, start.steps);
  }

  /// The count the cook set in an editor that opened with [start] portions;
  /// `null` when it opened without a count and still stands at the default,
  /// which no one chose.
  int? portionsSetFrom(int? start) =>
      portions == (start ?? const RecipeEditorDraft().portions)
      ? start
      : portions;

  /// The draft with [texts] after the lines of [section]; empty texts are
  /// left out.
  RecipeEditorDraft withAddedLines(
    RecipeEditorSection section,
    Iterable<String> texts,
  ) => _withLines(section, [
    ...linesOf(section),
    for (final text in texts)
      if (text.trim().isNotEmpty) RecipeEditorLine(text: text.trim()),
  ]);

  /// The draft with the line at [index] of [section] reading [text]. An
  /// empty text removes the line.
  RecipeEditorDraft withLine(
    RecipeEditorSection section,
    int index,
    String text,
  ) {
    if (text.trim().isEmpty) {
      return withoutLine(section, index);
    }
    final lines = [...linesOf(section)];
    lines[index] = lines[index].withText(text.trim());
    return _withLines(section, lines);
  }

  /// The draft without the line at [index] of [section].
  RecipeEditorDraft withoutLine(RecipeEditorSection section, int index) =>
      _withLines(section, [...linesOf(section)]..removeAt(index));

  /// The draft with the removed [line] back at [index] of [section], or
  /// last when the list is shorter by now.
  RecipeEditorDraft withRestoredLine(
    RecipeEditorSection section,
    int index,
    RecipeEditorLine line,
  ) {
    final lines = linesOf(section);
    return _withLines(
      section,
      [...lines]..insert(index.clamp(0, lines.length), line),
    );
  }

  /// The draft with what [scanned] shows: its title when no name is typed,
  /// its servings when it names any, and its ingredients and steps after
  /// the lines there are.
  RecipeEditorDraft withScan(ScannedIngredientList scanned) {
    final title = scanned.title;
    final servings = scanned.servings;
    return copyWith(
          name: name.trim().isEmpty && title != null ? title : null,
          portions: servings != null && servings > 0 ? servings : null,
        )
        .withAddedLines(.ingredients, scanned.ingredients)
        .withAddedLines(.steps, scanned.steps);
  }

  /// The draft with the pasted [text] read by [readPastedRecipe]: its
  /// ingredients and steps after what is there, its title as the name while
  /// the name is empty, and its portions.
  RecipeEditorDraft withPastedText(String text) =>
      withScan(readPastedRecipe(text));

  /// The new recipe the draft describes, without id, made at [now], with
  /// the stored photo [imageAssetId].
  PreparedMeal newRecipe({required DateTime now, String? imageAssetId}) =>
      PreparedMeal(
        id: '',
        name: name.trim(),
        imageAssetId: imageAssetId,
        recipeUrl: recipeUrl,
        recipeIngredients: [for (final line in ingredients) line.text],
        recipeInstructions: [for (final step in steps) step.text],
        recipeLineWeights: recipeLineWeightsOf(ingredients),
        totalPortions: portions,
        remainingPortions: portions,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        createdAt: now,
        updatedAt: now,
        components: const [],
      );

  /// The [latest] saved recipe with the draft's changes, changed at [now],
  /// so that what arrived since the editor opened (an estimate, Vorrat
  /// items, ignored lines) stays. The draft's name, portions, ingredient
  /// lines and steps win. A line weight the editor left as it was on
  /// [original] takes the latest weight of its line. A new photo
  /// [imageAssetId] replaces the photo and image link, a new [recipeUrl]
  /// the link.
  PreparedMeal editedRecipe(
    PreparedMeal latest, {
    required DateTime now,
    String? imageAssetId,
  }) {
    final openedWeights = original?.recipeLineWeights ?? const {};
    final edited = latest
        .withIngredientLines([
          for (final line in ingredients)
            switch (line.saved) {
              final saved? when line.weight == openedWeights[saved] =>
                line.withWeight(latest.recipeLineWeights[saved]),
              _ => line,
            },
        ])
        .copyWith(
          name: name.trim(),
          recipeUrl: recipeUrl ?? latest.recipeUrl,
          recipeInstructions: [for (final step in steps) step.text],
          totalPortions: portions,
          remainingPortions: portions,
          updatedAt: now,
        );
    return imageAssetId == null
        ? edited
        : edited.copyWith(imageAssetId: imageAssetId, imageUrl: null);
  }

  /// Copy with.
  RecipeEditorDraft copyWith({
    String? recipeUrl,
    String? name,
    int? portions,
    Uint8List? photo,
  }) => RecipeEditorDraft(
    original: original,
    recipeUrl: recipeUrl ?? this.recipeUrl,
    name: name ?? this.name,
    portions: portions ?? this.portions,
    ingredients: ingredients,
    steps: steps,
    photo: photo ?? this.photo,
  );

  RecipeEditorDraft _withLines(
    RecipeEditorSection section,
    List<RecipeEditorLine> lines,
  ) => RecipeEditorDraft(
    original: original,
    recipeUrl: recipeUrl,
    name: name,
    portions: portions,
    ingredients: section == .ingredients ? lines : ingredients,
    steps: section == .steps ? lines : steps,
    photo: photo,
  );
}

bool _sameLines(List<RecipeEditorLine> lines, List<RecipeEditorLine> others) {
  if (lines.length != others.length) {
    return false;
  }
  for (final (index, line) in lines.indexed) {
    final other = others[index];
    if (line.text != other.text || line.weight != other.weight) {
      return false;
    }
  }
  return true;
}
