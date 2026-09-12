import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

/// Checks whether a character index forms a word boundary.
bool hasCookingInstructionMatchBoundaries({
  required String instruction,
  required int start,
  required int end,
}) {
  return isCookingInstructionBoundaryAt(instruction, start, lookBack: true) &&
      isCookingInstructionBoundaryAt(instruction, end, lookBack: false);
}

/// Checks whether an index forms a word boundary.
bool isCookingInstructionBoundaryAt(
  String text,
  int index, {
  required bool lookBack,
}) {
  if (lookBack) {
    return index <= 0 || !_isWordLike(text[index - 1]);
  }
  return index >= text.length || !_isWordLike(text[index]);
}

bool _isWordLike(String value) {
  return RegExp(r'^[0-9A-Za-zÀ-ÖØ-öø-ÿ]$').hasMatch(value);
}

/// Expands [start] backwards if a preceding quantity or adjective exists.
int expandMatchStartToIncludePrecedingAmount({
  required String instruction,
  required int start,
  required CookingFlowParserLocale parserLocale,
}) {
  if (start <= 0) {
    return 0;
  }
  final prefix = instruction.substring(0, start);
  final unitPattern = parserLocale.amountUnitPattern;
  final amountPattern = RegExp(
    r'(?:^|[\s,;.(])'
    '('
    '(?:'
    r'(?:\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)(?:\s*(?:-|–|bis)\s*\d+(?:[.,]\d+)?)?'
    '|eine?r?m?n?|zwei|drei|vier|fünf|sechs'
    r'|etwas|ein\s+wenig'
    ')'
    '(?:\\s*(?:$unitPattern|stk\\.?|stück))?'
    r'(?:\s*(?:große|großen|großes|kleine|kleinen|kleines|mittelgroße|mittelgroßen|mittlere|mittleren|frische|frischen|reife?n?))?'
    r'\s*)$',
    caseSensitive: false,
  );
  final match = amountPattern.firstMatch(prefix);
  if (match != null) {
    return start - match.group(1)!.length;
  }
  return start;
}

/// Expands [end] forward if a parenthesized quantity immediately follows.
int expandMatchEndToIncludeTrailingParentheses({
  required String instruction,
  required int end,
  required CookingFlowParserLocale parserLocale,
}) {
  if (end >= instruction.length) {
    return end;
  }
  final suffix = instruction.substring(end);
  final unitPattern = parserLocale.amountUnitPattern;
  final parenPattern = RegExp(
    '^\\s*\\([^)]*(?:$unitPattern|\\d|stk|stück)[^)]*\\)',
    caseSensitive: false,
  );
  final match = parenPattern.firstMatch(suffix);
  return match != null ? end + match.group(0)!.length : end;
}

/// Formats the replacement label for a matched ingredient.
String cookingInstructionMatchLabel({
  required String matchedText,
  required String fullMatchedText,
  required String amountLabel,
  required CookingFlowInstructionText text,
}) {
  final trimmedAmount = amountLabel.trim();
  if (trimmedAmount.isEmpty || trimmedAmount == text.unknownAmount) {
    return matchedText;
  }
  if (textAlreadyContainsAmountLabel(fullMatchedText, trimmedAmount)) {
    return fullMatchedText;
  }
  return '$matchedText ($trimmedAmount)';
}

/// Checks whether [text] already contains [amountLabel].
bool textAlreadyContainsAmountLabel(String text, String amountLabel) {
  final normalizedText = normalizeCookingInstructionAmountText(text);
  final normalizedAmount = normalizeCookingInstructionAmountText(amountLabel);
  return normalizedAmount.isNotEmpty &&
      normalizedText.contains(normalizedAmount);
}

/// Normalizes text by lowercasing and stripping whitespace.
String normalizeCookingInstructionAmountText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

/// Compiles a regex pattern for [matchText] respecting amount units.
RegExp cookingInstructionMatchPattern({
  required String matchText,
  required CookingFlowParserLocale parserLocale,
}) {
  final trimmed = matchText.trim();
  final amountUnitMatch = RegExp(
    '^'
    r'(\d+(?:[.,]\d+)?)'
    r'\s*'
    '(${parserLocale.amountUnitPattern})'
    r'\s+'
    r'(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (amountUnitMatch == null) {
    return RegExp(
      spaceFlexibleEscapedPattern(trimmed),
      caseSensitive: false,
      unicode: true,
    );
  }

  final amount = RegExp.escape(amountUnitMatch.group(1)!);
  final unit = RegExp.escape(amountUnitMatch.group(2)!);
  final name = spaceFlexibleEscapedPattern(amountUnitMatch.group(3)!);
  return RegExp(
    '$amount\\s*$unit\\s+$name',
    caseSensitive: false,
    unicode: true,
  );
}

/// Escapes [value] for regex matching while allowing variable whitespace.
String spaceFlexibleEscapedPattern(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(RegExp.escape)
      .join(r'\s+');
}
