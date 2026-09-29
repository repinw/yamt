/// Defines inventory item sort mode.
enum InventoryItemSortMode {
  /// Documented member.
  recentlyAddedDescending,

  /// Documented member.
  recentlyAddedAscending,

  /// Documented member.
  recentlyEatenDescending,

  /// Documented member.
  recentlyEatenAscending,

  /// Documented member.
  alphabeticalAscending,

  /// Documented member.
  alphabeticalDescending,

  /// Documented member.
  availableAmountAscending,

  /// Documented member.
  availableAmountDescending,
}

/// Field the Vorrat list sorts by, without its direction.
enum InventorySortCriterion {
  /// When the entry was added.
  added,

  /// When the entry was last eaten from.
  eaten,

  /// Name.
  alphabetical,

  /// Share left.
  amount;

  /// Direction a field starts with when picked: newest, A to Z, least first.
  InventoryItemSortMode get defaultMode => switch (this) {
    InventorySortCriterion.added =>
      InventoryItemSortMode.recentlyAddedDescending,
    InventorySortCriterion.eaten =>
      InventoryItemSortMode.recentlyEatenDescending,
    InventorySortCriterion.alphabetical =>
      InventoryItemSortMode.alphabeticalAscending,
    InventorySortCriterion.amount =>
      InventoryItemSortMode.availableAmountAscending,
  };
}

/// Field and direction of an [InventoryItemSortMode].
extension InventoryItemSortModeParts on InventoryItemSortMode {
  /// Field sorted by.
  InventorySortCriterion get criterion => switch (this) {
    InventoryItemSortMode.recentlyAddedDescending ||
    InventoryItemSortMode.recentlyAddedAscending =>
      InventorySortCriterion.added,
    InventoryItemSortMode.recentlyEatenDescending ||
    InventoryItemSortMode.recentlyEatenAscending =>
      InventorySortCriterion.eaten,
    InventoryItemSortMode.alphabeticalAscending ||
    InventoryItemSortMode.alphabeticalDescending =>
      InventorySortCriterion.alphabetical,
    InventoryItemSortMode.availableAmountAscending ||
    InventoryItemSortMode.availableAmountDescending =>
      InventorySortCriterion.amount,
  };

  /// Whether the smallest value comes first.
  bool get isAscending => switch (this) {
    InventoryItemSortMode.recentlyAddedAscending ||
    InventoryItemSortMode.recentlyEatenAscending ||
    InventoryItemSortMode.alphabeticalAscending ||
    InventoryItemSortMode.availableAmountAscending => true,
    InventoryItemSortMode.recentlyAddedDescending ||
    InventoryItemSortMode.recentlyEatenDescending ||
    InventoryItemSortMode.alphabeticalDescending ||
    InventoryItemSortMode.availableAmountDescending => false,
  };

  /// Same field, other direction.
  InventoryItemSortMode get flipped => switch (this) {
    InventoryItemSortMode.recentlyAddedDescending =>
      InventoryItemSortMode.recentlyAddedAscending,
    InventoryItemSortMode.recentlyAddedAscending =>
      InventoryItemSortMode.recentlyAddedDescending,
    InventoryItemSortMode.recentlyEatenDescending =>
      InventoryItemSortMode.recentlyEatenAscending,
    InventoryItemSortMode.recentlyEatenAscending =>
      InventoryItemSortMode.recentlyEatenDescending,
    InventoryItemSortMode.alphabeticalAscending =>
      InventoryItemSortMode.alphabeticalDescending,
    InventoryItemSortMode.alphabeticalDescending =>
      InventoryItemSortMode.alphabeticalAscending,
    InventoryItemSortMode.availableAmountAscending =>
      InventoryItemSortMode.availableAmountDescending,
    InventoryItemSortMode.availableAmountDescending =>
      InventoryItemSortMode.availableAmountAscending,
  };
}
