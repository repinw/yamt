/// Hero tags shared by widgets that live in different features.
abstract final class HeroTags {
  /// Image of a logged diary entry. The entry details page uses the same tag,
  /// so the image flies from the diary row into the page.
  static String loggedEntryImage(String entryId) =>
      'logged-entry-image-$entryId';

  /// Picture of a Vorrat food. The item hub uses the same tag, so the
  /// picture flies from the Vorrat row into the page.
  static String stockItemImage(String itemId) => 'stock-item-image-$itemId';

  /// Picture of a prepared meal in the Vorrat. The meal detail page uses the
  /// same tag.
  static String preparedMealImage(String mealId) =>
      'prepared-meal-image-$mealId';
}
