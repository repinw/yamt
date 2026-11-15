import 'package:yamt/core/utils/flexible_decimal_parser.dart';

/// [text] with its amount in the form the ingredient parser reads, as people
/// say it while cooking: number words ("eine Zwiebel"), halves ("eine halbe
/// Zitrone"), fractions ("½ Zwiebel"), kilo, liter, milliliter and pfund, a
/// scale's reading in kg or l ("1,250 kg", which the parser would take for
/// 1250 kg), a count of packs of a size ("eine 400 g Dose Tomaten", which the
/// parser would take for 1400 g), and an amount after a comma ("Öl, 30"). Vague
/// words stay as they are ("ein paar Tomaten").
///
/// This is for reading only: a line's stored text stays as it was written.
String normalizeCookLineText(String text) {
  final read = _amountRead(text);
  if (_afterComma.firstMatch(read) case final match?) {
    return cookTextJoinedAmount(match[1]!, match[2]!) ?? read;
  }
  return read;
}

String _amountRead(String text) {
  final digits = text
      .trim()
      .replaceAllMapped(_fraction, (match) {
        final part = _fractions[match[2]];
        return match[1] == null ? '$part' : '${match[1]} $part';
      })
      .replaceAllMapped(_hyphenSize, (match) => '${match[1]} ${match[2]} ');
  final word = _countWord(digits);
  final read = (word == null ? digits : '${word.count}${word.rest}')
      .replaceAllMapped(
        _namedUnit,
        (match) => '${match[1]} ${_unitOf(match[2]!.toLowerCase())}',
      )
      .replaceAllMapped(_pound, (match) {
        final quantity = _quantity(match[1]!);
        return quantity == null ? match[0]! : '${(quantity * 500).round()} g';
      })
      .replaceAllMapped(_scaleReading, (match) {
        final thousandths = int.parse(match[1]!) * 1000 + int.parse(match[2]!);
        final unit = match[3]!.toLowerCase() == 'kg' ? 'g' : 'ml';
        return '$thousandths $unit';
      });
  return _sizeBehindPacks(read, word?.count);
}

// The digits a word for a count at the start of [text] stands for ("eine" is
// 1, "halbe" is 1/2), and the text behind it; `null` without one. "ein" in a
// vague amount is no count.
({String count, String rest})? _countWord(String text) {
  if (_vague.hasMatch(text)) return null;
  if (_half.matchAsPrefix(text) case final half?) {
    return (count: '1/2', rest: text.substring(half.end));
  }
  if (_oneAndHalf.matchAsPrefix(text) case final oneAndHalf?) {
    return (count: '1 1/2', rest: text.substring(oneAndHalf.end));
  }
  if (_numberWord.matchAsPrefix(text) case final word?) {
    final count = _numberWords[word[0]!.toLowerCase()];
    return (count: '$count', rest: text.substring(word.end));
  }
  return null;
}

// [read] with a count of packs of a size in the form that reads as count times
// size: "1 400 g Dose Tomaten" is "1 Dose Tomaten à 400 g". The parser would
// read "1 400" as one number. [word] is the count when a word said it; digits
// alone stay one number ("1 400 g Mehl", "1 1/2 l Flasche Wasser") unless a
// pack follows a whole size.
String _sizeBehindPacks(String read, String? word) {
  final count = word ?? _leadingNumber.stringMatch(read);
  if (count == null || !read.startsWith('$count ')) return read;
  final sized = _sizeAhead.firstMatch(read.substring(count.length).trimLeft());
  if (sized == null) return read;
  final [size, unit, packs] = [sized[1]!, sized[2]!, sized[3]!.trim()];
  if (word == null && (size.contains('/') || !_packWord.hasMatch(packs))) {
    return read;
  }
  return [count, if (packs.isNotEmpty) packs, 'à', size, unit].join(' ');
}

/// Whether [text] starts with a pinch ("1 Prise Salz", "2 Spritzer Zitrone"),
/// which takes nothing on purpose, even with a digit.
bool cookTextIsPinch(String text) =>
    _pinch.hasMatch(normalizeCookLineText(text));

/// Whether [text] starts with an amount that counts ("2 Tassen Reis", "1
/// Becher Sahne"), so a line that takes nothing has to wait. No pinch, and no
/// words without a digit ("Salz", "etwas Öl", "Saft einer Zitrone").
bool cookTextStartsWithCount(String text) {
  final read = normalizeCookLineText(text);
  return _leadingDigit.hasMatch(read) && !_pinch.hasMatch(read);
}

/// What the food [name] of a counted line starts with when it is a scoop out of
/// a pack ("Tassen Reis", "Löffel Öl", "Handvoll Nüsse", "gehäufte EL Mehl").
/// No stock is counted in those, so a count of them is no count of pieces.
/// `null` for anything else, also for what stock may well be counted in
/// ("Becher Sahne", "Dose Tomaten", "Zehen Knoblauch", "Scheiben Brot").
({String measure, String food})? cookTextScoop(String name) {
  final match = _scoop.firstMatch(name.trim());
  return match == null ? null : (measure: match[1]!, food: match[2]!);
}

/// [text] to match against food names: [normalizeCookLineText], and a pinch
/// without its amount, so that "1 Prise Salz" looks for the food "Salz" alone.
String cookTextForMatch(String text) =>
    normalizeCookLineText(text).replaceFirst(_pinch, '').trim();

/// [food] and [amount], two parts said with a comma, as one line when [amount]
/// is only an amount ("Öl, 30 g", "Öl, 30", "Öl, 2 EL"); `null` when it is not.
/// A bare number counts grams. A size per pack ("je 400 g") always belongs to
/// the part before; any other amount only when that part has none yet.
String? cookTextJoinedAmount(String food, String amount) {
  final read = normalizeCookLineText(amount);
  if (_perPack.hasMatch(read)) return '$food $read';
  if (food.contains(_digit)) return null;
  if (_bareNumber.hasMatch(read)) return '$food $read g';
  if (_weightOnly.hasMatch(read)) return '$food $read';
  // The parser reads a spoon or piece only ahead of the food.
  return _countOnly.hasMatch(read) ? '$read $food' : null;
}

String _unitOf(String word) => switch (word) {
  'milliliter' => 'ml',
  'liter' => 'l',
  _ => 'kg',
};

double? _quantity(String raw) {
  var total = 0.0;
  for (final part in raw.trim().split(RegExp(r'\s+'))) {
    final value = switch (part.split('/')) {
      [final over, final under] when double.parse(under) != 0 =>
        double.parse(over) / double.parse(under),
      [final number] => parseFlexibleDecimal(number),
      _ => null,
    };
    if (value == null) return null;
    total += value;
  }
  return total;
}

// A letter must not follow a unit: "1 Literflasche" names no liter.
const _notLetter = '(?![a-zA-ZäöüÄÖÜß])';
const _quantityPattern = r'\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?';
const _weightPattern = 'g|gr|gramm|gram|kg|ml|cl|dl|l';
// How much of a measure: "ein guter Schuss", "1 gehäufter EL", "ganz kleine".
const _measureWords =
    '(?:(?:gut|groß|gross|klein|kräftig|kraeftig|ordentlich|reichlich|knapp|'
    r'gehäuft|gehaeuft|gestrichen|voll|leicht|stark|ganz)(?:e|er|es|en|em)?\s+)'
    '{0,2}';

const _fractions = {
  '½': '1/2',
  '¼': '1/4',
  '¾': '3/4',
  '⅓': '1/3',
  '⅔': '2/3',
  '⅛': '1/8',
};

const _numberWords = {
  'ein': 1,
  'eine': 1,
  'einen': 1,
  'einem': 1,
  'einer': 1,
  'zwei': 2,
  'drei': 3,
  'vier': 4,
  'fünf': 5,
  'sechs': 6,
  'sieben': 7,
  'acht': 8,
  'neun': 9,
  'zehn': 10,
  'elf': 11,
  'zwölf': 12,
};

final _fraction = RegExp(r'(?:(\d)\s*)?([½¼¾⅓⅔⅛])');
// "400-g-Dose" and "1-Liter-Flasche" name a size.
final _hyphenSize = RegExp(
  r'(\d)\s*-\s*(kilogramm|kilogram|kilos?|milliliter|liter|'
  '$_weightPattern'
  r')\s*-\s*(?=[a-zA-ZäöüÄÖÜß])',
  caseSensitive: false,
);
final _half = RegExp(
  r'^(?:ein(?:e|en|em|er|es)?\s+)?halb(?:e|er|en|em|es)?(?=\s+\S)',
  caseSensitive: false,
);
final _oneAndHalf = RegExp(
  r'^(?:anderthalb|eineinhalb)(?=\s+\S)',
  caseSensitive: false,
);
final _numberWord = RegExp(
  '^(?:${_numberWords.keys.join('|')})'
  r'(?=\s+\S)',
  caseSensitive: false,
);
// "ein paar Tomaten" is no 1.
final _vague = RegExp(
  r'^ein\w*\s+(?:kleines\s+)?(?:paar|wenig|bisschen|hauch|menge)'
  '$_notLetter',
  caseSensitive: false,
);
final _namedUnit = RegExp(
  r'(\d)\s*(kilogramm|kilogram|kilos?|milliliter|liter)'
  '$_notLetter',
  caseSensitive: false,
);
final _pound = RegExp(
  '($_quantityPattern)'
  r'\s*pfund'
  '$_notLetter',
  caseSensitive: false,
);
final _scaleReading = RegExp(
  r'(?<![\d.,])(\d+)[.,](\d{3})\s*(kg|l)'
  '$_notLetter',
  caseSensitive: false,
);
final _pinch = RegExp(
  '^(?:$_quantityPattern)'
  r'\s*'
  '$_measureWords'
  '(?:prisen?|messerspitzen?|msp|spritzer|schuss|schuß|tropfen)'
  '$_notLetter',
  caseSensitive: false,
);
final _scoop = RegExp(
  '^($_measureWords'
  r'(?:[a-zA-ZäöüÄÖÜß]*tassen?|[a-zA-ZäöüÄÖÜß]*l(?:ö|oe)ffel|hand\s?voll|'
  r'hände\s?voll|[a-zA-ZäöüÄÖÜß]*kellen?|schluck|klecks(?:e)?|stich(?:e)?|'
  'el|tl))'
  r'\s+(\S.*)$',
  caseSensitive: false,
);
final _leadingNumber = RegExp(r'^\d+');
// A size and what it is the size of: "200 g Becher Schmand", "400g-Dose".
final _sizeAhead = RegExp(
  r'^([1-9]\d*(?:[.,]\d+)?|0[.,]\d+|\d+/\d+)\s*'
  '($_weightPattern)'
  '$_notLetter'
  r'[\s-]*(.*)$',
  caseSensitive: false,
);
final _packWord = RegExp(
  '^(?:dosen?|becher|gl(?:as|äser|aeser)|flaschen?|packung(?:en)?|päckchen|'
  'tüten?|beutel|tuben?|kartons?|sack|säcke)'
  '$_notLetter',
  caseSensitive: false,
);
// The part after the last comma that is no decimal comma ("Öl, 1,5 kg").
final _afterComma = RegExp(r'^(.*\D),\s*(.+)$');
final _leadingDigit = RegExp(r'^\d');
final _digit = RegExp(r'\d');
final _bareNumber = RegExp(r'^\d+(?:[.,]\d+)?$');
final _weightOnly = RegExp(
  '^(?:$_quantityPattern)'
  r'\s*'
  '(?:$_weightPattern)'
  r'$',
  caseSensitive: false,
);
final _perPack = RegExp(
  r'^(?:je|à|á|a)\s*(?:'
  '$_quantityPattern'
  r')\s*'
  '(?:$_weightPattern)'
  r'$',
  caseSensitive: false,
);
final _countOnly = RegExp(
  '^(?:$_quantityPattern)'
  r'\s*(?:el|tl|esslöffel|teelöffel|stk|stück)\.?$',
  caseSensitive: false,
);
