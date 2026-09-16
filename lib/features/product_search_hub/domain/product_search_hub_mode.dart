/// Product search hub launch mode.
enum ProductSearchHubMode {
  /// Add selected products to inventory.
  inventory,

  /// Eat selected products from diary flows.
  diary,

  /// Return edited product result to the caller without persistence.
  selection,
}
