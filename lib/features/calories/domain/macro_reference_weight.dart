/// Body mass index up to which the whole body weight counts for macros.
const macroReferenceBmi = 25.0;

/// Share of the weight above [macroReferenceBmi] that still counts for macros.
const macroExcessWeightShare = 0.4;

/// Body weight that protein and fat targets are measured against.
///
/// Grams per kilogram describe what lean mass needs, and body fat needs almost
/// none of it. Above a BMI of 25 only [macroExcessWeightShare] of the extra
/// weight counts (adjusted body weight), so a heavy person does not get
/// protein and fat targets that eat up the whole calorie budget.
double macroReferenceWeightKg({
  required double weightKg,
  required double heightCm,
}) {
  if (heightCm <= 0) {
    return weightKg;
  }
  final heightM = heightCm / 100;
  final referenceBmiWeightKg = macroReferenceBmi * heightM * heightM;
  if (weightKg <= referenceBmiWeightKg) {
    return weightKg;
  }
  return referenceBmiWeightKg +
      (weightKg - referenceBmiWeightKg) * macroExcessWeightShare;
}

/// The macro reference weight when it is lower than [weightKg], else `null`.
///
/// A value means the user is above a BMI of 25 and should see why their
/// protein and fat targets are lower than the body weight suggests.
double? macroAdjustedWeightKg({
  required double weightKg,
  required double heightCm,
}) {
  final referenceWeightKg = macroReferenceWeightKg(
    weightKg: weightKg,
    heightCm: heightCm,
  );
  return referenceWeightKg < weightKg ? referenceWeightKg : null;
}
