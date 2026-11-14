/// A recipe line as the shopping list keeps it: the product as the name,
/// a bare count as the quantity, any other amount in front of it as the
/// note.
typedef ShoppingLineSplit = ({String name, String? note, int quantity});

final _count = RegExp(r'^[1-9]\d?$');

final _amount = RegExp(r'^(\d+([.,/]\d+)?|[½¼¾⅓⅔]|\d+-\d+)$');

/// Words of an amount that stand between the number and the product.
const _amountWords = {
  'g', 'kg', 'mg', 'ml', 'l', 'cl', 'dl', 'el', 'tl', 'msp', 'prise', //
  'prisen', 'stück', 'stk', 'dose', 'dosen', 'bund', 'zehe', 'zehen',
  'packung', 'packungen', 'pck', 'becher', 'glas', 'gläser', 'scheibe',
  'scheiben', 'tasse', 'tassen', 'handvoll', 'kleine', 'kleiner', 'kleines',
  'mittlere', 'mittlerer', 'mittleres', 'große', 'großer', 'großes', 'cup',
  'cups', 'tbsp', 'tsp', 'oz', 'lb', 'pinch', 'can', 'cans', 'clove',
  'cloves', 'small', 'medium', 'large', 'piece', 'pieces', 'gramm', 'liter',
  'milliliter', 'kilo', 'kilogramm', 'esslöffel', 'teelöffel', 'päckchen',
  'pkg', 'stange', 'stangen', 'blatt', 'blätter', 'würfel', 'flasche',
  'flaschen', 'zweig', 'zweige', 'messerspitze', 'tube', 'tuben', 'knolle',
  'knollen', 'kopf', 'köpfe', 'netz', 'beutel', 'tablespoon', 'tablespoons',
  'teaspoon', 'teaspoons', 'gram', 'grams', 'bunch', 'slice', 'slices',
};

/// Splits a recipe [line] into the product and the amount in front of it:
/// "2 Zwiebeln" is two of "Zwiebeln", "600 g Karotten" is "Karotten" with
/// the note "600 g", "1 mittlere Zwiebel" is "Zwiebel" with "1 mittlere". A
/// line without a leading amount stays the name whole; a line that is all
/// amount too.
ShoppingLineSplit splitShoppingLine(String line) {
  final whole = (name: line.trim(), note: null, quantity: 1);
  final words = line.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || !_amount.hasMatch(words.first)) return whole;
  var end = 1;
  while (end < words.length &&
      _amountWords.contains(words[end].toLowerCase().replaceAll('.', ''))) {
    end++;
  }
  if (end == words.length) return whole;
  final name = words.sublist(end).join(' ');
  if (end == 1 && _count.hasMatch(words.first)) {
    return (name: name, note: null, quantity: int.parse(words.first));
  }
  return (name: name, note: words.sublist(0, end).join(' '), quantity: 1);
}
