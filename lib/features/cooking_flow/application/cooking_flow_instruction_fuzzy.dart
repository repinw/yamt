import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:meta/meta.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_inventory.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

/// Minimum ratio score to accept a fuzzy instruction match.
const int cookingFuzzyInstructionMatchThreshold = 90;

/// Maximum number of tokens allowed in a fuzzy match span.
const int maxCookingFuzzyInstructionSpanTokens = 3;

/// Token position inside an instruction.
class CookingInstructionToken {
  /// Creates a token span.
  const CookingInstructionToken({
    required this.start,
    required this.end,
  });

  /// Token start offset in text.
  final int start;

  /// Token end offset in text.
  final int end;
}

/// Tokenized normalized fuzzy query.
@immutable
class CookingFuzzyQuery {
  /// Creates a fuzzy query.
  const CookingFuzzyQuery({
    required this.text,
    required this.tokenCount,
  });

  /// Normalized query text.
  final String text;

  /// Number of tokens in the query.
  final int tokenCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingFuzzyQuery &&
            other.text == text &&
            other.tokenCount == tokenCount;
  }

  @override
  int get hashCode => Object.hash(text, tokenCount);
}

/// Candidate match found by fuzzy comparison.
class FuzzyInstructionCandidate {
  /// Creates a candidate match.
  const FuzzyInstructionCandidate({
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
FuzzyInstructionCandidate? findBestFuzzyInstructionCandidate({
  required String instruction,
  required CookingIngredientReference reference,
  required List<CookingInstructionMatch> existingMatches,
  required CookingFlowParserLocale parserLocale,
  required bool Function(int start, int end) overlapsWithExisting,
}) {
  final tokens = cookingInstructionTokens(instruction);
  if (tokens.isEmpty) {
    return null;
  }

  final queries = reference.matchTexts
      .map(toCookingFuzzyQuery)
      .where((query) => query.text.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (queries.isEmpty) {
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
      final normalizedCandidate = normalizeCookingFuzzyText(candidateText);
      if (!_isViableCookingFuzzyCandidate(
        normalizedCandidate,
        parserLocale,
      )) {
        continue;
      }
      for (final query in queries) {
        if (tokenCount > query.tokenCount) {
          continue;
        }
        final score = _cookingFuzzyMatchScore(query.text, normalizedCandidate);
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
        if (bestCandidate == null || candidate.isBetterThan(bestCandidate)) {
          bestCandidate = candidate;
        }
      }
    }
  }
  return bestCandidate;
}

int _cookingFuzzyMatchScore(String query, String candidate) {
  if (!query.contains(' ') && !candidate.contains(' ')) {
    if (_isSingleTokenCookingTypo(query: query, candidate: candidate)) {
      return 100;
    }
    return fuzzywuzzy.ratio(query, candidate);
  }
  final partialScore = fuzzywuzzy.partialRatio(query, candidate);
  final tokenScore = fuzzywuzzy.tokenSetPartialRatio(query, candidate);
  return partialScore > tokenScore ? partialScore : tokenScore;
}

bool _isSingleTokenCookingTypo({
  required String query,
  required String candidate,
}) {
  return !query.contains(' ') &&
      !candidate.contains(' ') &&
      query.length >= 4 &&
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

/// Normalizes and counts tokens in [value] to build a [CookingFuzzyQuery].
CookingFuzzyQuery toCookingFuzzyQuery(String value) {
  final text = normalizeCookingFuzzyText(value);
  final tokenCount = text.split(RegExp(r'\s+')).where((token) {
    return token.isNotEmpty;
  }).length;
  return CookingFuzzyQuery(text: text, tokenCount: tokenCount);
}

bool _isViableCookingFuzzyCandidate(
  String value,
  CookingFlowParserLocale parserLocale,
) {
  final tokens = value.split(RegExp(r'\s+')).where((token) {
    return token.isNotEmpty &&
        !parserLocale.fuzzyInstructionStopWords.contains(token) &&
        !CookingFlowParserLocale.allSupported.fuzzyInstructionStopWords
            .contains(token);
  });
  return tokens.any((token) {
    return token.length >= 3 ||
        parserLocale.fuzzyShortIngredientTokens.contains(token);
  });
}

/// Normalizes text for fuzzy matching.
String normalizeCookingFuzzyText(String value) {
  return value
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[^0-9a-zäöü]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Tokenizes text into word ranges.
List<CookingInstructionToken> cookingInstructionTokens(String value) {
  return RegExp('[0-9A-Za-zÀ-ÖØ-öø-ÿ]+')
      .allMatches(value)
      .map(
        (match) => CookingInstructionToken(
          start: match.start,
          end: match.end,
        ),
      )
      .toList(growable: false);
}
