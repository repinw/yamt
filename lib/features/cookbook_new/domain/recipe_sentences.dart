/// One sentence of a recipe's steps and the number of its step, from 1.
typedef RecipeSentence = ({int step, String text});

// A full stop after one of these, or after a single letter on its own as in
// "z. B.", does not end a sentence. Units of time end one ("5 Min. Dann").
const _abbreviations = {
  'approx',
  'bspw',
  'bzw',
  'ca',
  'el',
  'evtl',
  'gem',
  'geh',
  'gestr',
  'ggf',
  'ggfs',
  'gr',
  'inkl',
  'mind',
  'msp',
  'pck',
  'pkg',
  'stk',
  'tbsp',
  'tl',
  'tsp',
  'usw',
};

// After these, a number with a full stop is an ordinal, as in "Im 2. Schritt".
const _ordinalWords = {'am', 'beim', 'dem', 'den', 'der', 'im', 'vom', 'zum'};

// Words that start a sentence and never follow an ordinal, as in "bis zum
// 3. Dann": the number ends the sentence before them. shortcut: a noun such
// as "Salz" after "zum 3." still joins; a list of known nouns would do better.
const _sentenceStarts = {
  'abschließend',
  'alles',
  'anschließend',
  'danach',
  'dann',
  'inzwischen',
  'jetzt',
  'nun',
  'währenddessen',
  'zuletzt',
  'zum',
};

final _firstWord = RegExp(r'^\p{L}+', unicode: true);

final _sentenceEnd = RegExp(r'(?<=[.!?])\s+(?=\p{Lu}|\d)', unicode: true);
// The last word before the full stop, standing on its own, and the word
// before it.
final _lastWord = RegExp(r'(?:^|(\S*)\s)(\p{L}+|\d+)\.$', unicode: true);
// A short form with inner full stops, such as "z.B." or "i.d.R.".
final _dottedShortForm = RegExp(r'(?:^|\s)(?:\p{L}\.){2,}$', unicode: true);

/// The sentences of [steps] in order, without empty ones. A sentence ends
/// with ".", "!" or "?" before a capital letter or a digit, except after a
/// common abbreviation such as "ca." or "z. B." and after an ordinal such
/// as "2." that starts a step or follows "im".
List<RecipeSentence> recipeSentences(List<String> steps) => [
  for (final (index, step) in steps.indexed)
    for (final text in _split(step.trim())) (step: index + 1, text: text),
];

Iterable<String> _split(String step) sync* {
  if (step.isEmpty) {
    return;
  }
  var sentence = '';
  final parts = step.split(_sentenceEnd);
  for (final (index, part) in parts.indexed) {
    sentence = sentence.isEmpty ? part : '$sentence $part';
    final next = index + 1 < parts.length ? parts[index + 1] : '';
    if (!_continues(sentence, next)) {
      yield sentence;
      sentence = '';
    }
  }
  if (sentence.isNotEmpty) {
    yield sentence;
  }
}

/// Whether the full stop at the end of [sentence] belongs to its last word,
/// with [next] the text that follows it.
bool _continues(String sentence, String next) {
  if (_dottedShortForm.hasMatch(sentence)) {
    return true;
  }
  final match = _lastWord.firstMatch(sentence);
  final word = match?.group(2)?.toLowerCase();
  if (word == null) {
    return false;
  }
  final before = match?.group(1)?.toLowerCase();
  if (int.tryParse(word) != null) {
    // ponytail: a number ends the sentence unless it starts the step or
    // follows an ordinal word; a parser of dates and lists would do better.
    final nextWord = _firstWord.stringMatch(next)?.toLowerCase();
    return before == null ||
        (_ordinalWords.contains(before) && !_sentenceStarts.contains(nextWord));
  }
  // A single letter after a number is a unit, as in "175 F.".
  return _abbreviations.contains(word) ||
      (word.length == 1 && int.tryParse(before ?? '') == null);
}
