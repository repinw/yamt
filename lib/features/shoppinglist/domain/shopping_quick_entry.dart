/// What the user typed into the add field, split into a quantity and the
/// product text.
typedef ShoppingQuickEntry = ({int quantity, String text});

final _leadingQuantity = RegExp(r'^(\d{1,2})\s*[x×]?\s+(.+)$');
final _leadingUnit = RegExp(
  r'^(g|gr|gramm|kg|kilo|mg|ml|cl|dl|l|liter|el|tl)(?=[\s.]|$)',
  caseSensitive: false,
);

/// Reads a leading count from [input]: "2 milk" and "3x eggs" ask for two and
/// three. A number above 99, or one in front of a unit as in "500 g mince",
/// is part of the product text, because a shopping entry counts pieces.
ShoppingQuickEntry parseShoppingQuickEntry(String input) {
  final text = input.trim();
  final match = _leadingQuantity.firstMatch(text);
  if (match == null) return (quantity: 1, text: text);
  final quantity = int.parse(match.group(1)!);
  final rest = match.group(2)!.trim();
  if (quantity < 1 || _leadingUnit.hasMatch(rest)) {
    return (quantity: 1, text: text);
  }
  return (quantity: quantity, text: rest);
}
