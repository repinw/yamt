const _leadingMarks = '<([{"\'';
const _trailingMarks = '>)]}\'",.!?;:';
const _openers = {')': '(', ']': '[', '}': '{'};

/// [value] without the quotes, brackets, and sentence marks around it, such
/// as the ones of "(https://example.de/rezept)." A closing bracket stays when
/// its opener stays: "https://example.de/Foo_(Bar)" keeps its ")".
String stripWrappedPunctuation(String value) {
  var start = 0;
  var end = value.length;

  while (start < end && _leadingMarks.contains(value[start])) {
    start += 1;
  }
  while (end > start && _endsWithLooseMark(value.substring(start, end))) {
    end -= 1;
  }

  return value.substring(start, end);
}

bool _endsWithLooseMark(String value) {
  final last = value[value.length - 1];
  if (!_trailingMarks.contains(last)) {
    return false;
  }
  final opener = _openers[last];
  return opener == null ||
      opener.allMatches(value).length < last.allMatches(value).length;
}
