import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_fuzzy.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_inventory.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_match_bounds.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';

export 'cooking_flow_instruction_match_bounds.dart';

/// Builds instruction segments with highlighted and replaced ingredient spans.
List<CookingFlowInstructionSegment> buildInstructionSegments({
  required String instruction,
  required List<CookingIngredientReference> ingredientReferences,
  required CookingFlowParserLocale parserLocale,
  required Map<String, RegExp> patternCache,
  required CookingFlowInstructionText text,
}) {
  if (instruction.trim().isEmpty) {
    return const <CookingFlowInstructionSegment>[];
  }

  final sortedReferences =
      List<CookingIngredientReference>.from(
        ingredientReferences,
      )..sort(
        (a, b) => b.longestMatchTextLength.compareTo(a.longestMatchTextLength),
      );

  final matches = <CookingInstructionMatch>[];
  for (final reference in sortedReferences) {
    _collectExactMatches(
      instruction: instruction,
      reference: reference,
      matches: matches,
      parserLocale: parserLocale,
      patternCache: patternCache,
      text: text,
    );
    _collectFuzzyMatches(
      instruction: instruction,
      reference: reference,
      matches: matches,
      parserLocale: parserLocale,
      text: text,
    );
  }

  return matches.isEmpty
      ? <CookingFlowInstructionSegment>[
          CookingFlowInstructionSegment(instruction),
        ]
      : _assembleSegments(instruction: instruction, matches: matches);
}

void _collectExactMatches({
  required String instruction,
  required CookingIngredientReference reference,
  required List<CookingInstructionMatch> matches,
  required CookingFlowParserLocale parserLocale,
  required Map<String, RegExp> patternCache,
  required CookingFlowInstructionText text,
}) {
  for (final matchText in reference.matchTexts) {
    final pattern = patternCache.putIfAbsent(
      matchText,
      () => cookingInstructionMatchPattern(
        matchText: matchText,
        parserLocale: parserLocale,
      ),
    );
    for (final match in pattern.allMatches(instruction)) {
      if (!hasCookingInstructionMatchBoundaries(
        instruction: instruction,
        start: match.start,
        end: match.end,
      )) {
        continue;
      }
      final resolvedMatch = _resolveExpandedMatch(
        instruction: instruction,
        start: match.start,
        end: match.end,
        reference: reference,
        existingMatches: matches,
        parserLocale: parserLocale,
        text: text,
      );
      if (resolvedMatch != null) {
        matches.add(resolvedMatch);
      }
    }
  }
}

void _collectFuzzyMatches({
  required String instruction,
  required CookingIngredientReference reference,
  required List<CookingInstructionMatch> matches,
  required CookingFlowParserLocale parserLocale,
  required CookingFlowInstructionText text,
}) {
  while (true) {
    final candidate = findBestFuzzyInstructionCandidate(
      instruction: instruction,
      reference: reference,
      existingMatches: matches,
      parserLocale: parserLocale,
      overlapsWithExisting: (start, end) => cookingInstructionMatchOverlaps(
        matches: matches,
        start: start,
        end: end,
      ),
    );
    if (candidate == null) {
      break;
    }
    final resolved = _resolveExpandedMatch(
      instruction: instruction,
      start: candidate.start,
      end: candidate.end,
      reference: reference,
      existingMatches: matches,
      parserLocale: parserLocale,
      text: text,
    );
    if (resolved == null) {
      break;
    }
    matches.add(resolved);
  }
}

CookingInstructionMatch? _resolveExpandedMatch({
  required String instruction,
  required int start,
  required int end,
  required CookingIngredientReference reference,
  required List<CookingInstructionMatch> existingMatches,
  required CookingFlowParserLocale parserLocale,
  required CookingFlowInstructionText text,
}) {
  final expStart = expandMatchStartToIncludePrecedingAmount(
    instruction: instruction,
    start: start,
    parserLocale: parserLocale,
  );
  final expEnd = expandMatchEndToIncludeTrailingParentheses(
    instruction: instruction,
    end: end,
    parserLocale: parserLocale,
  );
  final finalStart =
      cookingInstructionMatchOverlaps(
        matches: existingMatches,
        start: expStart,
        end: expEnd,
      )
      ? start
      : expStart;
  final finalEnd =
      cookingInstructionMatchOverlaps(
        matches: existingMatches,
        start: finalStart,
        end: expEnd,
      )
      ? end
      : expEnd;

  if (cookingInstructionMatchOverlaps(
    matches: existingMatches,
    start: finalStart,
    end: finalEnd,
  )) {
    return null;
  }

  final fullText = instruction.substring(finalStart, finalEnd);
  final baseText = instruction.substring(start, end);
  return CookingInstructionMatch(
    start: finalStart,
    end: finalEnd,
    label: cookingInstructionMatchLabel(
      matchedText: baseText,
      fullMatchedText: fullText,
      amountLabel: reference.displayAmountLabel,
      text: text,
    ),
  );
}

List<CookingFlowInstructionSegment> _assembleSegments({
  required String instruction,
  required List<CookingInstructionMatch> matches,
}) {
  final sortedMatches = List<CookingInstructionMatch>.from(matches)
    ..sort((left, right) => left.start.compareTo(right.start));
  final segments = <CookingFlowInstructionSegment>[];
  var cursor = 0;
  for (final match in sortedMatches) {
    if (match.start > cursor) {
      segments.add(
        CookingFlowInstructionSegment(
          instruction.substring(cursor, match.start),
        ),
      );
    }
    segments.add(
      CookingFlowInstructionSegment(match.label, isHighlight: true),
    );
    cursor = match.end;
  }
  if (cursor < instruction.length) {
    segments.add(CookingFlowInstructionSegment(instruction.substring(cursor)));
  }
  return segments;
}

/// Checks if [start]..[end] overlaps with any match in [matches].
bool cookingInstructionMatchOverlaps({
  required List<CookingInstructionMatch> matches,
  required int start,
  required int end,
}) {
  return matches.any((entry) => start < entry.end && end > entry.start);
}

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
    if (hasCookingInstructionMatchBoundaries(
      instruction: instruction,
      start: match.start,
      end: match.end,
    )) {
      yield match;
    }
  }
}
