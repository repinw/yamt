/// A duration a recipe sentence names, such as "10–15 Minuten": the
/// `shortest` the timer suggests and the `longest` of a range.
typedef CookDuration = ({Duration shortest, Duration longest});

/// The durations [sentence] names, in German or English, in order. Vague
/// ones ("über Nacht", "kurz") and clock times ("um 18 Uhr") give none.
/// "1 Stunde 20 Minuten" is one duration; a range ("10–15 Minuten",
/// "10 bis 15 Min.") gives its bounds.
List<CookDuration> cookDurationsIn(String sentence) {
  final text = sentence.toLowerCase();
  final found = <CookDuration>[];
  var rest = text;
  while (true) {
    final match = _duration.firstMatch(rest);
    if (match == null) break;
    final before = rest.substring(0, match.start);
    final durationText = match.group(0)!;
    rest = rest.substring(match.end);
    if (_clockBefore.hasMatch(before)) continue;
    final duration = _parse(durationText);
    if (duration != null) found.add(duration);
  }
  return found;
}

/// The timers a button for [duration] offers: the duration itself, or both
/// bounds of a range ("10–15 Minuten" offers 10 and 15 minutes).
List<Duration> cookTimerSteps(CookDuration duration) => [
  duration.shortest,
  if (duration.longest != duration.shortest) duration.longest,
];

// A number word or digits, an optional range, a unit; then optionally a
// second number and smaller unit ("1 Std. 20 Min.").
final _duration = RegExp(
  '\\b(?:$_number)(?:\\s*(?:-|–|bis|to|or|oder)\\s*(?:$_number))?\\s*'
  '(?:$_unit)$_end(?:\\s*(?:und|and)?\\s*(?:$_number)\\s*(?:$_unit)$_end)?',
);

// Fractions first ("1 1/2", "3/4"), so their parts are not read alone.
// Number words end where no letter follows: "an hour" but not "and".
const _number =
    r'\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?|'
    '(?:eine?n?|einer|halbe?n?|anderthalb|one|an?|half(?: an)?|'
    '$_words)$_end';

// Number words for 2 to 12, German and English, read by [_value].
const _words =
    'zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf|'
    'two|three|four|five|six|seven|eight|nine|ten|eleven|twelve';

const _unit =
    r'stunden|stunde|std\.?|h|hours?|hrs?\.?|minuten|minute|min\.?|'
    r'minutes?|mins?\.?|sekunden|sekunde|sek\.?|seconds?|secs?\.?|s';

// A unit ends where no letter follows: "10 Min." but not "10 mindestens".
const _end = '(?![a-zäöüß])';

// "um 18 Uhr", "at 6": a clock time, not a duration.
final _clockBefore = RegExp(r'(?:\bum|\bat|\bgegen)\s*$');

CookDuration? _parse(String text) {
  final parts = RegExp('\\b($_number)\\s*(?:($_unit)$_end)?').allMatches(text);
  final values = <({double value, String? unit})>[];
  for (final part in parts) {
    final value = _value(part.group(1)!);
    if (value == null) continue;
    values.add((value: value, unit: part.group(2)));
  }
  if (values.isEmpty) return null;
  final isRange = RegExp(r'-|–|\bbis\b|\bto\b|\bor\b|\boder\b').hasMatch(text);
  if (isRange && values.length >= 2 && values[0].unit == null) {
    final unit = values[1].unit!;
    return _bounds(_of(values[0].value, unit), _of(values[1].value, unit));
  }
  var total = Duration.zero;
  for (final (:value, :unit) in values) {
    if (unit == null) return null;
    total += _of(value, unit);
  }
  return total == Duration.zero ? null : (shortest: total, longest: total);
}

CookDuration? _bounds(Duration low, Duration high) {
  if (low <= Duration.zero || high < low) return null;
  return (shortest: low, longest: high);
}

double? _value(String word) => switch (word.trim()) {
  'ein' || 'eine' || 'einen' || 'einer' || 'one' || 'a' || 'an' => 1,
  'halb' || 'halbe' || 'halben' || 'half' || 'half an' => 0.5,
  'anderthalb' => 1.5,
  final number => _wordValue(number) ?? _fraction(number) ?? _decimal(number),
};

double? _wordValue(String word) {
  final index = _words.split('|').indexOf(word);
  return index < 0 ? null : (index % 11 + 2).toDouble();
}

// "1/2" or "1 1/2".
double? _fraction(String text) {
  final match = RegExp(r'^(?:(\d+)\s+)?(\d+)/(\d+)$').firstMatch(text);
  if (match == null) return null;
  final denominator = int.parse(match.group(3)!);
  if (denominator == 0) return null;
  final whole = int.parse(match.group(1) ?? '0');
  return whole + int.parse(match.group(2)!) / denominator;
}

double? _decimal(String digits) => double.tryParse(digits.replaceAll(',', '.'));

Duration _of(double value, String unit) {
  final seconds = unit.startsWith('st') || unit.startsWith('h')
      ? value * 3600
      : unit.startsWith('m')
      ? value * 60
      : value;
  return Duration(seconds: seconds.round());
}
