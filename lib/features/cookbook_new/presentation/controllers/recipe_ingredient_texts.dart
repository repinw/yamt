import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// [requirement] with [amount], which can be a fraction, as an ingredient
/// text: "800 g Hackfleisch", "2,67 Tomaten". A changed amount for other
/// portions is written this way for the recipe's own ones, so it comes back
/// exactly when it is scaled again.
String recipeIngredientTextFor(
  TemplateIngredientRequirement requirement,
  double amount,
) {
  final measure = requirement.countMeasureLabel?.trim() ?? '';
  final unit = measure.isNotEmpty
      ? measure
      : requirement.unit == TemplateIngredientUnit.piece
      ? null
      : requirement.unit.code;
  // Two decimals at most: three would read as a thousands group.
  final rounded = (amount * 100).round() / 100;
  final number = rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : '$rounded'.replaceFirst('.', ',');
  return [number, ?unit, requirement.name].join(' ');
}

/// [text], an ingredient the cook adds for the chosen portions of [view],
/// written for the recipe's own portions like the saved ingredients.
String recipeAddedText(
  TemplateIngredientParser parser,
  RecipeView view,
  String text,
) {
  if (view.portions == view.basePortions) {
    return text;
  }
  // The parser rounds to whole units, so it scales a hundredfold for two
  // decimals.
  final scaled = parser.parseRequirement(
    ingredient: text,
    selectedPortions: view.basePortions * 100,
    basePortions: view.portions,
  );
  return scaled == null
      ? text
      : recipeIngredientTextFor(scaled, scaled.amount / 100);
}
