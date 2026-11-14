import 'dart:convert';

import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// A stable fingerprint of [items], the same for the same entries in any
/// order, so a save can skip a list that did not change.
String shoppingListSignature(List<ShoppingListItem> items) => jsonEncode([
  for (final item in [...items]..sort((a, b) => a.id.compareTo(b.id)))
    item.toJson(),
]);

/// What the repository knows about the private list, so a save never
/// replaces entries it could not see.
///
/// The live watch decides whether the list is readable. While it is not, a
/// save leaves the private list alone, unless its private entries hold all
/// the ones a later full read saw: then the caller knows the whole list.
/// After a full read that failed, no save writes the list until a read
/// succeeds: a replace would delete what could not be read.
class ShoppingPrivateListState {
  bool _readable = true;
  String? _stored;
  Set<String>? _readIds;
  bool _lastReadFailed = false;

  /// Whether the live watch failed and no watch read the list since, or the
  /// last full read failed.
  bool get isUnreadable => !_readable || _lastReadFailed;

  /// The watch failed: the list counts as empty and unknown.
  void markUnreadable() {
    _readable = false;
    _stored = shoppingListSignature(const []);
    _readIds = null;
  }

  /// A full read failed; what it returned holds no private entries.
  void markReadFailed() => _lastReadFailed = true;

  /// Records [items] as stored. A read [fromWatch] marks the list readable;
  /// a full read only records which entries it saw.
  void recordRead(List<ShoppingListItem> items, {required bool fromWatch}) {
    _stored = shoppingListSignature(items);
    _readIds = {for (final item in items) item.id};
    _lastReadFailed = false;
    if (fromWatch) _readable = true;
  }

  /// Whether a save with the private entries [own] may write the list.
  bool mayWrite(List<ShoppingListItem> own) {
    if (_lastReadFailed) return false;
    if (_readable) return true;
    final read = _readIds;
    return read != null &&
        own.isNotEmpty &&
        {for (final item in own) item.id}.containsAll(read);
  }

  /// Whether [own] differs from what is stored.
  bool differs(List<ShoppingListItem> own) =>
      shoppingListSignature(own) != _stored;

  /// Records [own] as written.
  void recordWrite(List<ShoppingListItem> own) =>
      _stored = shoppingListSignature(own);
}
