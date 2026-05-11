import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

export 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// The template ingredient parser provider.
final templateIngredientParserProvider = Provider<TemplateIngredientParser>((
  ref,
) {
  return const TemplateIngredientParser();
});
