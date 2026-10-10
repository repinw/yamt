/// Where a food for an open row comes from, besides the Vorrat.
enum PreparedMealFoodSource {
  /// The product search.
  search,

  /// The barcode scanner.
  barcode,

  /// The AI estimate.
  ai,
}
