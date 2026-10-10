/// Splits spoken or typed text into ingredient rows.
///
/// Speech recognition returns no commas, so a new row starts before each
/// amount: "500 g Hähnchen 40 g Butter" gives "500 g Hähnchen" and
/// "40 g Butter". Commas, line breaks, and "und" or "and" also end a row. An
/// amount without a food ("Hähnchen 500 g") stays with the row before it.
List<String> splitFreeCookingTranscript(String transcript) {
  final rows = <String>[];
  for (final part in transcript.split(_rowSeparator)) {
    for (final segment in _splitBeforeAmounts(part)) {
      if (rows.isNotEmpty && _amountOnly.hasMatch(segment)) {
        rows.last = '${rows.last} $segment';
      } else {
        rows.add(segment);
      }
    }
  }
  return rows;
}

List<String> _splitBeforeAmounts(String text) {
  final segments = <List<String>>[];
  String? previous;
  for (final token in text.trim().split(_whitespace)) {
    if (token.isEmpty) {
      continue;
    }
    final startsAmount = _startsWithDigit.hasMatch(token);
    final followsAmount = previous != null && _number.hasMatch(previous);
    if (segments.isEmpty || (startsAmount && !followsAmount)) {
      segments.add(<String>[token]);
    } else {
      segments.last.add(token);
    }
    previous = token;
  }
  return [for (final segment in segments) segment.join(' ')];
}

final _rowSeparator = RegExp(
  r'\s*(?:,(?!\d)|[;\n]|\bund\b|\band\b)\s*',
  caseSensitive: false,
);
final _whitespace = RegExp(r'\s+');
final _startsWithDigit = RegExp(r'^\d');
final _number = RegExp(r'^\d+(?:[.,]\d+)?$|^\d+/\d+$');
final _amountOnly = RegExp(
  r'^\d+(?:[.,/]\d+)?\s*'
  r'(?:g|gr|gramm|kg|ml|l|liter|el|tl|stk|stück|prise|prisen)?\.?$',
  caseSensitive: false,
);

/// What is left of [transcript] after undo words such as "nein" at its
/// start, or `null` when it does not start with one: "Nein, nein!" and
/// "nein, doch nicht" leave nothing, "nein, 200 g Sahne" leaves the
/// correction.
String? afterUndoWords(String transcript) {
  final match = _leadingUndo.firstMatch(transcript);
  return match == null ? null : transcript.substring(match.end).trim();
}

final _leadingUndo = RegExp(
  r'^\s*(?:(?:nein|no|rückgängig|undo)(?![\p{L}\d])[\s\p{P}]*)+'
  r'(?:(?:doch|nicht|danke)(?![\p{L}\d])[\s\p{P}]*)*',
  caseSensitive: false,
  unicode: true,
);
