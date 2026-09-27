import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_inventory.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

/// Minimum ratio score to accept a fuzzy instruction match.
const int cookingFuzzyInstructionMatchThreshold = 90;

/// Maximum number of tokens allowed in a fuzzy match span.
const int maxCookingFuzzyInstructionSpanTokens = 3;

/// Token position inside an instruction.
class CookingInstructionToken {
  /// Creates a token span.
  const new({required this.start, required this.end});

  /// Token start offset in text.
  final int start;

  /// Token end offset in text.
  final int end;
}

/// Candidate match found by fuzzy comparison.
class FuzzyInstructionCandidate {
  /// Creates a candidate match.
  const new({
    required this.start,
    required this.end,
    required this.score,
    required this.tokenCount,
    required this.textLength,
    required this.candidateText,
  });

  /// Start offset in instruction.
  final int start;

  /// End offset in instruction.
  final int end;

  /// Match score between 0 and 100.
  final int score;

  /// Number of tokens in candidate.
  final int tokenCount;

  /// Character length of candidate.
  final int textLength;

  /// Substring matched in instruction.
  final String candidateText;

  /// Whether this candidate is ranked higher than [other].
  bool isBetterThan(FuzzyInstructionCandidate? other) {
    if (other == null) {
      return true;
    }
    if (score != other.score) {
      return score > other.score;
    }
    if (tokenCount != other.tokenCount) {
      return tokenCount < other.tokenCount;
    }
    return textLength > other.textLength;
  }
}

/// Finds the best fuzzy candidate matching [reference] in [instruction].
///
/// A candidate is a span of up to [maxCookingFuzzyInstructionSpanTokens]
/// tokens that starts and ends with a word that is not a stop word. Stop words
/// inside the span are ignored, and every other word must match a word of the
/// query, so a shared stop word such as "oder" earns no credit.
FuzzyInstructionCandidate? findBestFuzzyInstructionCandidate({
  required String instruction,
  required CookingIngredientReference reference,
  required CookingFlowParserLocale parserLocale,
  required bool Function(int start, int end) overlapsWithExisting,
}) {
  final tokens = cookingInstructionTokens(instruction);
  final queries = _cookingFuzzyQueries(reference, parserLocale);
  if (tokens.isEmpty || queries.isEmpty) {
    return null;
  }

  FuzzyInstructionCandidate? bestCandidate;
  for (var startIndex = 0; startIndex < tokens.length; startIndex++) {
    for (
      var tokenCount = 1;
      tokenCount <= maxCookingFuzzyInstructionSpanTokens;
      tokenCount++
    ) {
      final endIndex = startIndex + tokenCount - 1;
      if (endIndex >= tokens.length) {
        break;
      }
      final start = tokens[startIndex].start;
      final end = tokens[endIndex].end;
      if (overlapsWithExisting(start, end)) {
        continue;
      }
      final candidateText = instruction.substring(start, end);
      final candidateWords = _cookingFuzzySpanWords(
        candidateText,
        parserLocale,
      );
      if (candidateWords == null) {
        continue;
      }
      for (final query in queries) {
        final score = _cookingFuzzyMatchScore(query, candidateWords);
        if (score < cookingFuzzyInstructionMatchThreshold) {
          continue;
        }
        final candidate = FuzzyInstructionCandidate(
          start: start,
          end: end,
          score: score,
          tokenCount: tokenCount,
          textLength: end - start,
          candidateText: candidateText,
        );
        if (candidate.isBetterThan(bestCandidate)) {
          bestCandidate = candidate;
        }
      }
    }
  }
  return bestCandidate;
}

/// Query alternatives for [reference], one word list each.
///
/// Every name variant loses its parenthesised qualifiers, comma details, stop
/// words, and short fragments. A name with several words also adds its last
/// word, so "kleine Tomaten" still finds a plain "Tomaten".
List<List<String>> _cookingFuzzyQueries(
  CookingIngredientReference reference,
  CookingFlowParserLocale parserLocale,
) {
  final queries = <String, List<String>>{};
  void addQuery(List<String> words) {
    queries.putIfAbsent(words.join(' '), () => words);
  }

  for (final matchText in reference.nameMatchTexts) {
    final words = _cookingFuzzyWords(cleanIngredientReferenceName(matchText))
        .where((word) => _isCookingFuzzyQueryWord(word, parserLocale))
        .toList(growable: false);
    if (words.isEmpty) {
      continue;
    }
    addQuery(words);
    final lastWord = words.last;
    if (words.length > 1 &&
        (lastWord.length >= 4 ||
            parserLocale.fuzzyShortIngredientTokens.contains(lastWord))) {
      addQuery(<String>[lastWord]);
    }
  }
  return queries.values.toList(growable: false);
}

bool _isCookingFuzzyQueryWord(
  String word,
  CookingFlowParserLocale parserLocale,
) {
  return !_isCookingFuzzyStopWord(word, parserLocale) &&
      (word.length >= 3 ||
          parserLocale.fuzzyShortIngredientTokens.contains(word));
}

/// Words of a candidate span without stop words, or `null` when the span
/// starts or ends with a stop word.
List<String>? _cookingFuzzySpanWords(
  String candidateText,
  CookingFlowParserLocale parserLocale,
) {
  final words = _cookingFuzzyWords(candidateText);
  if (words.isEmpty ||
      _isCookingFuzzyStopWord(words.first, parserLocale) ||
      _isCookingFuzzyStopWord(words.last, parserLocale)) {
    return null;
  }
  return words
      .where((word) => !_isCookingFuzzyStopWord(word, parserLocale))
      .toList(growable: false);
}

bool _isCookingFuzzyStopWord(
  String word,
  CookingFlowParserLocale parserLocale,
) {
  return parserLocale.fuzzyInstructionStopWords.contains(word) ||
      CookingFlowParserLocale.allSupported.fuzzyInstructionStopWords.contains(
        word,
      );
}

int _cookingFuzzyMatchScore(List<String> query, List<String> candidate) {
  if (candidate.length > query.length ||
      !candidate.every(
        (word) =>
            query.any((queryWord) => _cookingFuzzyWordsMatch(queryWord, word)),
      )) {
    return 0;
  }
  if (query.length == 1) {
    return _isCookingTypo(query.single, candidate.single)
        ? 100
        : fuzzywuzzy.ratio(query.single, candidate.single);
  }
  return fuzzywuzzy.tokenSortRatio(query.join(' '), candidate.join(' '));
}

bool _cookingFuzzyWordsMatch(String queryWord, String candidateWord) {
  return queryWord == candidateWord ||
      _isCookingTypo(queryWord, candidateWord) ||
      fuzzywuzzy.ratio(queryWord, candidateWord) >=
          cookingFuzzyInstructionMatchThreshold;
}

bool _isCookingTypo(String query, String candidate) {
  return query.length >= 4 &&
      candidate.length >= 4 &&
      _cookingEditDistanceAtMostOne(query, candidate);
}

bool _cookingEditDistanceAtMostOne(String left, String right) {
  if ((left.length - right.length).abs() > 1) {
    return false;
  }
  var leftIndex = 0;
  var rightIndex = 0;
  var edits = 0;
  while (leftIndex < left.length && rightIndex < right.length) {
    if (left.codeUnitAt(leftIndex) == right.codeUnitAt(rightIndex)) {
      leftIndex += 1;
      rightIndex += 1;
      continue;
    }
    edits += 1;
    if (edits > 1) {
      return false;
    }
    if (left.length > right.length) {
      leftIndex += 1;
    } else if (right.length > left.length) {
      rightIndex += 1;
    } else {
      leftIndex += 1;
      rightIndex += 1;
    }
  }
  if (leftIndex < left.length || rightIndex < right.length) {
    edits += 1;
  }
  return edits <= 1;
}

List<String> _cookingFuzzyWords(String value) {
  return normalizeCookingFuzzyText(value)
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
}

/// Normalizes text for fuzzy matching.
String normalizeCookingFuzzyText(String value) {
  return value
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[^0-9a-zà-öø-ÿ]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Tokenizes text into word ranges.
List<CookingInstructionToken> cookingInstructionTokens(String value) {
  return RegExp('[0-9A-Za-zÀ-ÖØ-öø-ÿ]+')
      .allMatches(value)
      .map(
        (match) => CookingInstructionToken(start: match.start, end: match.end),
      )
      .toList(growable: false);
}
