/// Returns all safe ingredient mention matches inside one instruction line.
Iterable<RegExpMatch> findCookflowIngredientMentionMatches({
  required String instruction,
  required String ingredientName,
}) sync* {
  final trimmedIngredient = ingredientName.trim();
  if (instruction.isEmpty || trimmedIngredient.isEmpty) {
    return;
  }

  final pattern = RegExp(
    RegExp.escape(trimmedIngredient),
    caseSensitive: false,
    unicode: true,
  );
  for (final match in pattern.allMatches(instruction)) {
    if (_hasCookflowIngredientBoundaries(
      instruction: instruction,
      start: match.start,
      end: match.end,
    )) {
      yield match;
    }
  }
}

bool _hasCookflowIngredientBoundaries({
  required String instruction,
  required int start,
  required int end,
}) {
  return _isBoundaryAt(instruction, start, lookBack: true) &&
      _isBoundaryAt(instruction, end, lookBack: false);
}

bool _isBoundaryAt(
  String text,
  int index, {
  required bool lookBack,
}) {
  if (lookBack) {
    if (index <= 0) {
      return true;
    }
    return !_isWordLikeChar(text[index - 1]);
  }
  if (index >= text.length) {
    return true;
  }
  return !_isWordLikeChar(text[index]);
}

bool _isWordLikeChar(String char) {
  return RegExp('[0-9A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(char);
}
