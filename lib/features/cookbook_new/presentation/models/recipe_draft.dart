import 'package:meta/meta.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_edits.dart';

/// What the cook changed on the recipe page.
@immutable
class RecipeDraft {
  /// Creates the draft.
  const new({
    this.portions,
    this.picks = const <String, String?>{},
    this.edits = const RecipeEdits(),
    this.justAdded = const <String>[],
    this.fromGuide = const <String>[],
    this.withGuide = true,
    this.isCooking = false,
  });

  /// The chosen portions, or `null` for the recipe's own.
  final int? portions;

  /// The Vorrat item picked per line key; `null` means "not from the
  /// Vorrat".
  final Map<String, String?> picks;

  /// What the cook changes in the recipe this time.
  final RecipeEdits edits;

  /// The line keys of the ingredients the Kochhelfer added last, which
  /// "Rückgängig" takes out again.
  final List<String> justAdded;

  /// The line keys of every ingredient the Kochhelfer added that is still
  /// in [edits]. They stay until the recipe page closes.
  final List<String> fromGuide;

  /// Whether "Kochen" opens the Kochhelfer first, for a recipe with steps.
  final bool withGuide;

  /// Whether "Kochen" is saving the meal.
  final bool isCooking;

  /// Returns a copy with the given values.
  RecipeDraft copyWith({
    int? portions,
    Map<String, String?>? picks,
    RecipeEdits? edits,
    List<String>? justAdded,
    List<String>? fromGuide,
    bool? withGuide,
    bool? isCooking,
  }) => RecipeDraft(
    portions: portions ?? this.portions,
    picks: picks ?? this.picks,
    edits: edits ?? this.edits,
    justAdded: justAdded ?? this.justAdded,
    fromGuide: fromGuide ?? this.fromGuide,
    withGuide: withGuide ?? this.withGuide,
    isCooking: isCooking ?? this.isCooking,
  );
}
