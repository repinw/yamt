import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_chef_exclusions.freezed.dart';
part 'ai_chef_exclusions.g.dart';

/// Ingredients the user never wants in an AI recipe.
///
/// The list keeps the order in which the user added the entries. Entries are
/// trimmed and unique without regard to case.
@freezed
abstract class AiChefExclusions with _$AiChefExclusions {
  /// Creates the list.
  const factory({required List<String> ingredients}) = _AiChefExclusions;

  const new _();

  /// Reads the stored list.
  factory fromJson(Map<String, dynamic> json) =>
      _$AiChefExclusionsFromJson(json);

  /// The list without entries.
  static const empty = AiChefExclusions(ingredients: <String>[]);

  /// The list with [ingredient] added at the end.
  ///
  /// Returns this list when [ingredient] is blank or already in it.
  AiChefExclusions add(String ingredient) {
    final trimmed = ingredient.trim();
    if (trimmed.isEmpty || _contains(trimmed)) {
      return this;
    }
    return AiChefExclusions(ingredients: [...ingredients, trimmed]);
  }

  /// The list without [ingredient].
  AiChefExclusions remove(String ingredient) {
    return AiChefExclusions(
      ingredients: [
        for (final entry in ingredients)
          if (entry != ingredient) entry,
      ],
    );
  }

  bool _contains(String ingredient) {
    final key = ingredient.toLowerCase();
    return ingredients.any((entry) => entry.toLowerCase() == key);
  }
}
