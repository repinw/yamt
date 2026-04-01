class MealTemplateIngredient {
  const MealTemplateIngredient({
    required this.id,
    required this.name,
    this.baseAmount,
    this.unit,
    this.isIgnored = false,
  });

  final String id;
  final String name;
  final double? baseAmount;
  final String? unit;
  final bool isIgnored;
}
