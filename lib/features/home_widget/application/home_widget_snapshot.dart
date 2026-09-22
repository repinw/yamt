/// Render-ready snapshot written to native widget storage. Flat and plain
/// so Kotlin/Swift code reads simple fields, not domain object graphs.
class HomeWidgetSnapshot {
  /// Creates a home-widget snapshot.
  const new({
    required this.verbose,
    required this.eatenKcal,
    required this.targetKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
    required this.updatedAt,
  });

  /// Whether the widget should render its verbose layout.
  final bool verbose;

  /// Kcal eaten today.
  final double eatenKcal;

  /// Kcal target for today.
  final double targetKcal;

  /// Eaten protein in grams.
  final double proteinGrams;

  /// Eaten carbs in grams.
  final double carbsGrams;

  /// Eaten fat in grams.
  final double fatGrams;

  /// Target protein in grams.
  final double proteinGoalGrams;

  /// Target carbs in grams.
  final double carbsGoalGrams;

  /// Target fat in grams.
  final double fatGoalGrams;

  /// When this snapshot was built.
  final DateTime updatedAt;

  /// Converts to a plain JSON map for native widget code.
  Map<String, dynamic> toJson() => {
    'verbose': verbose,
    'eaten_kcal': eatenKcal,
    'target_kcal': targetKcal,
    'protein_grams': proteinGrams,
    'carbs_grams': carbsGrams,
    'fat_grams': fatGrams,
    'protein_goal_grams': proteinGoalGrams,
    'carbs_goal_grams': carbsGoalGrams,
    'fat_goal_grams': fatGoalGrams,
    'updated_at': updatedAt.toIso8601String(),
  };
}
