import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

export 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'template_ingredient_parser.g.dart';

/// The template ingredient parser provider.
@Riverpod(keepAlive: true)
TemplateIngredientParser templateIngredientParser(Ref ref) {
  return const TemplateIngredientParser();
}
