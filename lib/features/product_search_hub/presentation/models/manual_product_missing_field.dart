/// An input the product editor still needs before it can save.
enum ManualProductMissingField {
  /// The product name.
  name,

  /// The package size or its unit.
  packageSize,

  /// Energy per 100 g.
  energy,

  /// Fat per 100 g.
  fat,

  /// Saturated fat per 100 g.
  saturatedFat,

  /// Carbohydrate per 100 g.
  carbs,

  /// Sugars per 100 g.
  sugar,

  /// Protein per 100 g.
  protein,

  /// Salt per 100 g.
  salt,

  /// The barcode, or the mark that the product has none.
  barcode,
}
