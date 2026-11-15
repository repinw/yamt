import 'package:meta/meta.dart';

/// What the photos of a recipe show.
@immutable
class ScannedIngredientList {
  /// Creates a scanned ingredient list.
  const new({
    required this.title,
    required this.servings,
    required this.ingredients,
    required this.steps,
  });

  /// Reads the template's answer: an optional `title` and `servings`, and
  /// the lists `ingredients` and `steps`. Lines are trimmed, empty ones
  /// dropped, and an empty title becomes `null`. Throws a [FormatException]
  /// for any other shape.
  factory fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('Expected an ingredient list object', json);
    }
    final title = json['title'];
    final servings = json['servings'];
    if (title is! String?) {
      throw FormatException('Expected a title string', title);
    }
    if (servings is! int?) {
      throw FormatException('Expected an integer servings count', servings);
    }
    final trimmedTitle = title?.trim();
    return ScannedIngredientList(
      title: trimmedTitle == null || trimmedTitle.isEmpty ? null : trimmedTitle,
      servings: servings,
      ingredients: _lines(json['ingredients']),
      steps: _lines(json['steps']),
    );
  }

  /// The recipe title, or `null` when the photos show none.
  final String? title;

  /// The number of servings, or `null` when the photos show none.
  final int? servings;

  /// One ingredient per line, as written.
  final List<String> ingredients;

  /// The preparation steps in order, as written.
  final List<String> steps;

  static List<String> _lines(Object? value) {
    if (value is! List<Object?>) {
      throw FormatException('Expected a list of lines', value);
    }
    return [
      for (final line in value)
        if (line is! String)
          throw FormatException('Expected a line string', line)
        else if (line.trim().isNotEmpty)
          line.trim(),
    ];
  }
}
