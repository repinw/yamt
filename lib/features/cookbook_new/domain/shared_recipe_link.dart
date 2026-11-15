import 'package:yamt/features/inventory/domain/wrapped_punctuation.dart';

/// The web link that the shared [text] stands for, without the punctuation
/// around it: a lone link, or one link with up to two short lines such as a
/// title and "Rezept auf …:", as browsers and recipe apps share a page.
/// `null` when the text holds no link, more than one, more lines besides it,
/// a longer line, or a line that starts with an amount and a unit such as
/// "200 g Mehl", so it is a recipe to paste. A title such as "15 Minuten
/// Pasta" or "5-Zutaten-Brot" is no amount.
String? sharedRecipeLink(String text) {
  final trimmed = text.trim();
  final words = [
    for (final word in trimmed.split(RegExp(r'\s+')))
      if (_isWebLink(stripWrappedPunctuation(word))) word,
  ];
  if (words.length != 1) {
    return null;
  }
  final word = words.single;
  final rest = [
    for (final line in trimmed.replaceFirst(word, '').split(RegExp(r'\r?\n')))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return rest.length > _maxLinesBesideLink ||
          rest.any(
            (line) =>
                line.length > _maxLineLengthBesideLink ||
                _amountLine.hasMatch(line),
          )
      ? null
      : stripWrappedPunctuation(word);
}

const _maxLinesBesideLink = 2;
const _maxLineLengthBesideLink = 120;

// A negative lookahead, not `\b`, since `\b` takes "ü" for a word's end.
final _amountLine = RegExp(
  r'^\d+(?:[.,/]\d+)?\s*(?:kg|g|gr|gramm|mg|ml|cl|dl|l|liter|el|tl|msp|stk|'
  'stück|prise|prisen|pck|päckchen|dose|dosen|bund|becher|tasse|tassen)'
  '(?![a-zA-ZäöüÄÖÜß])',
  caseSensitive: false,
);

bool _isWebLink(String word) {
  final uri = Uri.tryParse(word);
  return uri != null &&
      (uri.isScheme('http') || uri.isScheme('https')) &&
      uri.host.isNotEmpty;
}
