/// Hero tags shared by widgets that live in different features.
abstract final class HeroTags {
  /// Image of a logged diary entry. The entry details sheet uses the same tag,
  /// so the image flies from the diary row into the sheet.
  static String loggedEntryImage(String entryId) =>
      'logged-entry-image-$entryId';
}
