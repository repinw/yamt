import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Which list the page shows: the one shared with the household, the
/// private one of the user, or both for one trip through the shop.
enum ShoppingListScope {
  /// The household list.
  household,

  /// The private list.
  private,

  /// Both lists together.
  both;

  /// Whether [item] shows in this scope.
  bool shows(ShoppingListItem item) => switch (this) {
    household => !item.isPrivate,
    private => item.isPrivate,
    both => true,
  };

  /// Whether a new entry goes on the private list. In [both] it goes on
  /// the household list.
  bool get addsPrivate => this == private;
}
