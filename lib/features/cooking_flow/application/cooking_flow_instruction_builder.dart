import 'dart:isolate';

import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:meta/meta.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Localized labels needed by the instruction builder.
@immutable
class CookingFlowInstructionText {
  /// Creates localized instruction builder text.
  const CookingFlowInstructionText({
    required this.unknownAmount,
    required this.fallbackNoIngredients,
    required this.fallbackPrepPrefix,
    required this.fallbackCookText,
  });

  /// Unknown amount label.
  final String unknownAmount;

  /// Fallback line when no ingredients exist.
  final String fallbackNoIngredients;

  /// Fallback prep line prefix.
  final String fallbackPrepPrefix;

  /// Fallback cooking line.
  final String fallbackCookText;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingFlowInstructionText &&
            other.unknownAmount == unknownAmount &&
            other.fallbackNoIngredients == fallbackNoIngredients &&
            other.fallbackPrepPrefix == fallbackPrepPrefix &&
            other.fallbackCookText == fallbackCookText;
  }

  @override
  int get hashCode => Object.hash(
    unknownAmount,
    fallbackNoIngredients,
    fallbackPrepPrefix,
    fallbackCookText,
  );
}

/// Cookflow instruction step with highlighted ingredient segments.
class CookingFlowInstructionStep {
  /// Creates instruction step.
  const CookingFlowInstructionStep({required this.segments});

  /// Rich-text segments for this instruction.
  final List<CookingFlowInstructionSegment> segments;
}

/// Segment inside one instruction line.
class CookingFlowInstructionSegment {
  /// Creates instruction segment.
  const CookingFlowInstructionSegment(this.text, {this.isHighlight = false});

  /// Segment text.
  final String text;

  /// Whether segment should be highlighted.
  final bool isHighlight;
}

/// Builds localized cooking instruction steps and ingredient highlights.
List<CookingFlowInstructionStep> buildCookingFlowInstructionSteps({
  required PreparedMeal template,
  required CookingFlowIntroDraft? introDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInstructionText text,
  required String localeCode,
}) {
  final ingredientReferences = _buildIngredientReferences(
    template: template,
    introDraft: introDraft,
    inventoryItems: inventoryItems,
    text: text,
    localeCode: localeCode,
  );
  final parserLocale = CookingFlowParserLocale.forLocaleCode(localeCode);
  final sourceInstructions = template.recipeInstructions
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final baseInstructions = sourceInstructions.isEmpty
      ? _buildFallbackCookingInstructions(
          ingredientReferences: ingredientReferences,
          text: text,
        )
      : sourceInstructions;

  return baseInstructions
      .map(
        (instruction) => CookingFlowInstructionStep(
          segments: _buildInstructionSegments(
            instruction: instruction,
            ingredientReferences: ingredientReferences,
            parserLocale: parserLocale,
          ),
        ),
      )
      .toList(growable: false);
}

/// Builds instruction steps on a worker isolate to avoid UI-thread jank.
Future<List<CookingFlowInstructionStep>>
buildCookingFlowInstructionStepsOffMain({
  required PreparedMeal template,
  required CookingFlowIntroDraft? introDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInstructionText text,
  required String localeCode,
}) {
  return Isolate.run(
    () => buildCookingFlowInstructionSteps(
      template: template,
      introDraft: introDraft,
      inventoryItems: inventoryItems,
      text: text,
      localeCode: localeCode,
    ),
    debugName: 'CookingFlowInstructionBuilder',
  );
}

List<String> _buildFallbackCookingInstructions({
  required List<_CookingIngredientReference> ingredientReferences,
  required CookingFlowInstructionText text,
}) {
  if (ingredientReferences.isEmpty) {
    return <String>[text.fallbackNoIngredients];
  }

  final ingredientSummary = ingredientReferences
      .map((reference) {
        final amountLabel = reference.displayAmountLabel.isEmpty
            ? text.unknownAmount
            : reference.displayAmountLabel;
        return '$amountLabel ${reference.name}';
      })
      .join(', ');
  return <String>[
    '${text.fallbackPrepPrefix} $ingredientSummary.',
    text.fallbackCookText,
  ];
}

List<CookingFlowInstructionSegment> _buildInstructionSegments({
  required String instruction,
  required List<_CookingIngredientReference> ingredientReferences,
  required CookingFlowParserLocale parserLocale,
}) {
  if (instruction.trim().isEmpty) {
    return const <CookingFlowInstructionSegment>[];
  }

  final sortedReferences =
      List<_CookingIngredientReference>.from(
        ingredientReferences,
      )..sort((left, right) {
        return right.longestMatchTextLength.compareTo(
          left.longestMatchTextLength,
        );
      });
  final matches = <_InstructionMatch>[];
  final patternCache = <String, RegExp>{};
  for (final reference in sortedReferences) {
    for (final matchText in reference.matchTexts) {
      final pattern = patternCache.putIfAbsent(
        matchText,
        () => _cookingInstructionMatchPattern(
          matchText: matchText,
          parserLocale: parserLocale,
        ),
      );
      for (final match in pattern.allMatches(instruction)) {
        if (!_hasCookingInstructionMatchBoundaries(
          instruction: instruction,
          start: match.start,
          end: match.end,
        )) {
          continue;
        }
        if (_cookingInstructionMatchOverlaps(
          matches: matches,
          start: match.start,
          end: match.end,
        )) {
          continue;
        }
        final matchedText = instruction.substring(match.start, match.end);
        matches.add(
          _InstructionMatch(
            start: match.start,
            end: match.end,
            label: _cookingInstructionMatchLabel(
              matchedText: matchedText,
              amountLabel: reference.displayAmountLabel,
            ),
          ),
        );
      }
    }
    final fuzzyMatch = _bestFuzzyCookingInstructionMatch(
      instruction: instruction,
      reference: reference,
      existingMatches: matches,
      parserLocale: parserLocale,
    );
    if (fuzzyMatch != null) {
      matches.add(fuzzyMatch);
    }
  }

  if (matches.isEmpty) {
    return <CookingFlowInstructionSegment>[
      CookingFlowInstructionSegment(instruction),
    ];
  }

  matches.sort((left, right) => left.start.compareTo(right.start));
  final segments = <CookingFlowInstructionSegment>[];
  var cursor = 0;
  for (final match in matches) {
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

RegExp _cookingInstructionMatchPattern({
  required String matchText,
  required CookingFlowParserLocale parserLocale,
}) {
  return RegExp(
    _cookingInstructionPatternSource(
      matchText: matchText,
      parserLocale: parserLocale,
    ),
    caseSensitive: false,
    unicode: true,
  );
}

String _cookingInstructionPatternSource({
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
    return _spaceFlexibleEscapedPattern(trimmed);
  }

  final amount = RegExp.escape(amountUnitMatch.group(1)!);
  final unit = RegExp.escape(amountUnitMatch.group(2)!);
  final name = _spaceFlexibleEscapedPattern(amountUnitMatch.group(3)!);
  return '$amount\\s*$unit\\s+$name';
}

String _spaceFlexibleEscapedPattern(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(RegExp.escape)
      .join(r'\s+');
}

bool _hasCookingInstructionMatchBoundaries({
  required String instruction,
  required int start,
  required int end,
}) {
  return _isCookingInstructionBoundaryAt(
        instruction,
        start,
        lookBack: true,
      ) &&
      _isCookingInstructionBoundaryAt(instruction, end, lookBack: false);
}

bool _isCookingInstructionBoundaryAt(
  String text,
  int index, {
  required bool lookBack,
}) {
  if (lookBack) {
    if (index <= 0) {
      return true;
    }
    return !_isCookingInstructionWordLike(text[index - 1]);
  }
  if (index >= text.length) {
    return true;
  }
  return !_isCookingInstructionWordLike(text[index]);
}

bool _isCookingInstructionWordLike(String value) {
  return RegExp(r'^[0-9A-Za-zÀ-ÖØ-öø-ÿ]$').hasMatch(value);
}

String _cookingInstructionMatchLabel({
  required String matchedText,
  required String amountLabel,
}) {
  final trimmedAmount = amountLabel.trim();
  if (trimmedAmount.isEmpty ||
      _textAlreadyContainsAmountLabel(matchedText, trimmedAmount)) {
    return matchedText;
  }
  return '$matchedText ($trimmedAmount)';
}

bool _textAlreadyContainsAmountLabel(String text, String amountLabel) {
  final normalizedText = _normalizeCookingInstructionAmountText(text);
  final normalizedAmount = _normalizeCookingInstructionAmountText(amountLabel);
  return normalizedAmount.isNotEmpty &&
      normalizedText.contains(normalizedAmount);
}

String _normalizeCookingInstructionAmountText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

bool _cookingInstructionMatchOverlaps({
  required List<_InstructionMatch> matches,
  required int start,
  required int end,
}) {
  return matches.any((entry) => start < entry.end && end > entry.start);
}

_InstructionMatch? _bestFuzzyCookingInstructionMatch({
  required String instruction,
  required _CookingIngredientReference reference,
  required List<_InstructionMatch> existingMatches,
  required CookingFlowParserLocale parserLocale,
}) {
  final tokens = _cookingInstructionTokens(instruction);
  if (tokens.isEmpty) {
    return null;
  }

  final queries = reference.matchTexts
      .map(_cookingFuzzyQuery)
      .where((query) => query.text.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (queries.isEmpty) {
    return null;
  }

  _FuzzyCookingInstructionMatch? bestMatch;
  for (var startIndex = 0; startIndex < tokens.length; startIndex++) {
    for (
      var tokenCount = 1;
      tokenCount <= _maxCookingFuzzyInstructionSpanTokens;
      tokenCount++
    ) {
      final endIndex = startIndex + tokenCount - 1;
      if (endIndex >= tokens.length) {
        break;
      }
      final start = tokens[startIndex].start;
      final end = tokens[endIndex].end;
      if (_cookingInstructionMatchOverlaps(
        matches: existingMatches,
        start: start,
        end: end,
      )) {
        continue;
      }
      final candidateText = instruction.substring(start, end);
      final normalizedCandidate = _normalizeCookingFuzzyText(candidateText);
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
        if (score < _cookingFuzzyInstructionMatchThreshold) {
          continue;
        }
        final candidate = _FuzzyCookingInstructionMatch(
          start: start,
          end: end,
          score: score,
          tokenCount: tokenCount,
          textLength: end - start,
          label: _cookingInstructionMatchLabel(
            matchedText: candidateText,
            amountLabel: reference.displayAmountLabel,
          ),
        );
        if (bestMatch == null || candidate.isBetterThan(bestMatch)) {
          bestMatch = candidate;
        }
      }
    }
  }
  return bestMatch?.toInstructionMatch();
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
      query.length >= 5 &&
      candidate.length >= 5 &&
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

_CookingFuzzyQuery _cookingFuzzyQuery(String value) {
  final text = _normalizeCookingFuzzyText(value);
  final tokenCount = text.split(RegExp(r'\s+')).where((token) {
    return token.isNotEmpty;
  }).length;
  return _CookingFuzzyQuery(text: text, tokenCount: tokenCount);
}

bool _isViableCookingFuzzyCandidate(
  String value,
  CookingFlowParserLocale parserLocale,
) {
  final tokens = value.split(RegExp(r'\s+')).where((token) {
    return token.isNotEmpty &&
        !parserLocale.fuzzyInstructionStopWords.contains(
          token,
        ) &&
        !CookingFlowParserLocale.allSupported.fuzzyInstructionStopWords
            .contains(token);
  });
  return tokens.any((token) {
    return token.length >= 3 ||
        parserLocale.fuzzyShortIngredientTokens.contains(
          token,
        );
  });
}

String _normalizeCookingFuzzyText(String value) {
  return value
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[^0-9a-zäöü]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

List<_CookingInstructionToken> _cookingInstructionTokens(String value) {
  return RegExp('[0-9A-Za-zÀ-ÖØ-öø-ÿ]+')
      .allMatches(value)
      .map(
        (match) => _CookingInstructionToken(
          start: match.start,
          end: match.end,
        ),
      )
      .toList(growable: false);
}

List<_CookingIngredientReference> _buildIngredientReferences({
  required PreparedMeal template,
  required CookingFlowIntroDraft? introDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInstructionText text,
  required String localeCode,
}) {
  final parserLocale = CookingFlowParserLocale.forLocaleCode(localeCode);
  final introRows = <String, CookingFlowIntroRowDraft>{
    for (final row
        in introDraft?.rowStates ?? const <CookingFlowIntroRowDraft>[])
      row.rawIngredient: row,
  };
  final rows = template.components.isNotEmpty
      ? template.components
            .map(
              (component) => _CookingIngredientRowData(
                rawIngredient:
                    '${component.usedAmount}${component.usedUnit.code} '
                    '${component.name}',
                name: component.name,
                amountLabel:
                    '${component.usedAmount}${component.usedUnit.code}',
              ),
            )
            .toList(growable: false)
      : template.recipeIngredients
            .map((ingredient) {
              return _cookingIngredientRowFromRecipeIngredient(
                ingredient,
                text,
                parserLocale,
              );
            })
            .toList(growable: false);

  return rows
      .map((row) {
        final rowDraft = introRows[row.rawIngredient];
        final displayAmountLabel = _resolveCookingIngredientAmountLabel(
          row: row,
          rowDraft: rowDraft,
          inventoryItems: inventoryItems,
          parserLocale: parserLocale,
        );
        return _CookingIngredientReference(
          rawIngredient: row.rawIngredient,
          name: row.name,
          displayAmountLabel: displayAmountLabel,
        );
      })
      .toList(growable: false);
}

_CookingIngredientRowData _cookingIngredientRowFromRecipeIngredient(
  String ingredient,
  CookingFlowInstructionText text,
  CookingFlowParserLocale parserLocale,
) {
  final trimmed = ingredient.trim();
  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
  if (requirement != null) {
    return _CookingIngredientRowData(
      rawIngredient: ingredient,
      name: requirement.name,
      amountLabel: _cookflowCookingRequirementAmountLabel(requirement),
    );
  }

  final amountWithUnitMatch = RegExp(
    '^('
    r'\d+(?:[.,]\d+)?'
    '(?:\\s?(?:${parserLocale.amountUnitPattern}))'
    r')\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (amountWithUnitMatch != null) {
    return _CookingIngredientRowData(
      rawIngredient: ingredient,
      name: amountWithUnitMatch.group(2)!.trim(),
      amountLabel: amountWithUnitMatch.group(1)!.trim(),
    );
  }

  final amountOnlyMatch = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(.+)$',
  ).firstMatch(trimmed);
  if (amountOnlyMatch != null) {
    return _CookingIngredientRowData(
      rawIngredient: ingredient,
      name: amountOnlyMatch.group(2)!.trim(),
      amountLabel: amountOnlyMatch.group(1)!.trim(),
    );
  }

  return _CookingIngredientRowData(
    rawIngredient: ingredient,
    name: trimmed,
    amountLabel: text.unknownAmount,
  );
}

String _cookflowCookingRequirementAmountLabel(
  TemplateIngredientRequirement requirement,
) {
  final packageCountLabel = requirement.packageCountLabel?.trim();
  if (packageCountLabel?.isNotEmpty == true &&
      requirement.unit.code != _cookingPieceUnitCode) {
    return '$packageCountLabel ${requirement.amount}${requirement.unit.code}';
  }
  final countMeasureLabel = requirement.countMeasureLabel?.trim();
  if (countMeasureLabel?.isNotEmpty == true) {
    return '${requirement.amount} $countMeasureLabel';
  }
  if (requirement.unit.code == 'pc') {
    return requirement.amount.toString();
  }
  return '${requirement.amount} ${requirement.unit.code}';
}

String _resolveCookingIngredientAmountLabel({
  required _CookingIngredientRowData row,
  required CookingFlowIntroRowDraft? rowDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowParserLocale parserLocale,
}) {
  if (rowDraft == null ||
      rowDraft.action != CookingFlowIntroRowAction.assigned) {
    return row.amountLabel;
  }

  final requirement = _parseCookingInventoryRequirement(
    row.amountLabel,
    parserLocale,
  );
  final inventoryById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id: item,
  };
  final selectedItems = rowDraft.selections
      .where((selection) => !selection.isAdditionalIngredient)
      .map((selection) => inventoryById[selection.itemId])
      .whereType<InventoryItem>()
      .toList(growable: false);
  if (selectedItems.isEmpty) {
    return row.amountLabel;
  }

  final selectedAmount = _selectedCookingInventoryAmount(selectedItems);
  if (selectedAmount != null &&
      _shouldUseSelectedCookingAmount(
        requirement: requirement,
        selectedAmount: selectedAmount,
      )) {
    return selectedAmount.label;
  }

  if (rowDraft.conflictResolution !=
      CookingFlowIntroConflictResolution.adjustTemplate) {
    return row.amountLabel;
  }
  if (requirement == null) {
    return row.amountLabel;
  }

  final availableAmount = _availableCookingInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  );
  return _formatCookingInventoryRequirementAmount(
    amount: availableAmount,
    unitCode: requirement.unitCode,
  );
}

({String label, String unitCode})? _selectedCookingInventoryAmount(
  List<InventoryItem> selectedItems,
) {
  InventoryAmountUnit? sharedUnit;
  var sharedScale = 1;
  var totalAmount = 0;

  for (final item in selectedItems) {
    final itemUnit = item.amountUnit;
    if (!item.usesAmountProgress || itemUnit == null) {
      if (sharedUnit != null &&
          (sharedUnit != InventoryAmountUnit.piece || sharedScale != 1)) {
        return null;
      }
      sharedUnit ??= InventoryAmountUnit.piece;
      sharedScale = 1;
      totalAmount += item.quantity;
      continue;
    }
    if (sharedUnit == null) {
      sharedUnit = itemUnit;
      sharedScale = item.amountScale;
    } else if (sharedUnit != itemUnit || sharedScale != item.amountScale) {
      return null;
    }
    totalAmount += item.currentAmount;
  }

  if (sharedUnit == null || totalAmount < 1) {
    return null;
  }
  final amountLabel = formatInventoryAmountValue(
    amount: totalAmount,
    unit: sharedUnit,
    scale: sharedScale,
  );
  final label = sharedUnit == InventoryAmountUnit.piece
      ? amountLabel
      : '$amountLabel${sharedUnit.code}';
  return (label: label, unitCode: sharedUnit.code);
}

bool _shouldUseSelectedCookingAmount({
  required _CookingInventoryRequirement? requirement,
  required ({String label, String unitCode}) selectedAmount,
}) {
  if (requirement == null) {
    return true;
  }
  return requirement.unitCode == _cookingPieceUnitCode &&
      selectedAmount.unitCode != _cookingPieceUnitCode;
}

_CookingInventoryRequirement? _parseCookingInventoryRequirement(
  String value,
  CookingFlowParserLocale parserLocale,
) {
  final trimmed = _stripCookingPackageCountPrefix(value);
  if (trimmed.isEmpty) {
    return null;
  }

  final match = RegExp(
    r'^([\d.,\s/]+)(?:\s*([a-zA-ZäöüÄÖÜß]+))?$',
  ).firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  final rawAmount = parseCookingFlowQuantity(match.group(1)!);
  if (rawAmount == null) {
    return null;
  }

  final rawUnit = match.group(2)?.trim().toLowerCase();
  if (parserLocale.isPieceUnit(rawUnit)) {
    return _CookingInventoryRequirement(
      amount: rawAmount.round(),
      unitCode: _cookingPieceUnitCode,
    );
  }
  return switch (rawUnit) {
    null || '' => _CookingInventoryRequirement(
      amount: rawAmount.round(),
      unitCode: _cookingPieceUnitCode,
    ),
    'g' => _CookingInventoryRequirement(
      amount: rawAmount.round(),
      unitCode: 'g',
    ),
    'kg' => _CookingInventoryRequirement(
      amount: (rawAmount * 1000).round(),
      unitCode: 'g',
    ),
    'mg' => _CookingInventoryRequirement(
      amount: (rawAmount / 1000).round(),
      unitCode: 'g',
    ),
    'ml' => _CookingInventoryRequirement(
      amount: rawAmount.round(),
      unitCode: 'ml',
    ),
    'cl' => _CookingInventoryRequirement(
      amount: (rawAmount * 10).round(),
      unitCode: 'ml',
    ),
    'dl' => _CookingInventoryRequirement(
      amount: (rawAmount * 100).round(),
      unitCode: 'ml',
    ),
    'l' => _CookingInventoryRequirement(
      amount: (rawAmount * 1000).round(),
      unitCode: 'ml',
    ),
    _ => null,
  };
}

String _stripCookingPackageCountPrefix(String value) {
  final trimmed = value.trim();
  final match = RegExp(
    r'^\d+(?:[.,]\d+)?\s*x\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  return match?.group(1)?.trim() ?? trimmed;
}

int _availableCookingInventoryAmount({
  required List<InventoryItem> selectedItems,
  required _CookingInventoryRequirement requirement,
}) {
  var total = 0;
  for (final item in selectedItems) {
    if (requirement.unitCode == _cookingPieceUnitCode) {
      if (item.usesAmountProgress && item.amountUnit?.code == 'pc') {
        total += item.currentAmount;
        continue;
      }
      total += item.quantity;
      continue;
    }

    if (!item.usesAmountProgress ||
        item.amountUnit?.code != requirement.unitCode) {
      continue;
    }
    total += item.currentAmount;
  }
  return total;
}

String _formatCookingInventoryRequirementAmount({
  required int amount,
  required String unitCode,
}) {
  if (unitCode == _cookingPieceUnitCode) {
    return amount.toString();
  }
  return '$amount$unitCode';
}

class _CookingIngredientReference {
  const _CookingIngredientReference({
    required this.rawIngredient,
    required this.name,
    required this.displayAmountLabel,
  });

  final String rawIngredient;
  final String name;
  final String displayAmountLabel;

  List<String> get matchTexts {
    final seen = <String>{};
    return <String>[rawIngredient, name]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
        .toList(growable: false);
  }

  int get longestMatchTextLength {
    return matchTexts.fold<int>(0, (longest, text) {
      return text.length > longest ? text.length : longest;
    });
  }
}

class _CookingInstructionToken {
  const _CookingInstructionToken({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}

class _CookingIngredientRowData {
  const _CookingIngredientRowData({
    required this.rawIngredient,
    required this.name,
    required this.amountLabel,
  });

  final String rawIngredient;
  final String name;
  final String amountLabel;
}

class _InstructionMatch {
  const _InstructionMatch({
    required this.start,
    required this.end,
    required this.label,
  });

  final int start;
  final int end;
  final String label;
}

class _FuzzyCookingInstructionMatch {
  const _FuzzyCookingInstructionMatch({
    required this.start,
    required this.end,
    required this.score,
    required this.tokenCount,
    required this.textLength,
    required this.label,
  });

  final int start;
  final int end;
  final int score;
  final int tokenCount;
  final int textLength;
  final String label;

  bool isBetterThan(_FuzzyCookingInstructionMatch? other) {
    if (other == null) {
      return true;
    }
    if (score != other.score) {
      return score > other.score;
    }
    if (tokenCount != other.tokenCount) {
      return tokenCount < other.tokenCount;
    }
    if (textLength != other.textLength) {
      return textLength < other.textLength;
    }
    return start < other.start;
  }

  _InstructionMatch toInstructionMatch() {
    return _InstructionMatch(
      start: start,
      end: end,
      label: label,
    );
  }
}

@immutable
class _CookingFuzzyQuery {
  const _CookingFuzzyQuery({
    required this.text,
    required this.tokenCount,
  });

  final String text;
  final int tokenCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CookingFuzzyQuery &&
            other.text == text &&
            other.tokenCount == tokenCount;
  }

  @override
  int get hashCode => Object.hash(text, tokenCount);
}

class _CookingInventoryRequirement {
  const _CookingInventoryRequirement({
    required this.amount,
    required this.unitCode,
  });

  final int amount;
  final String unitCode;
}

const String _cookingPieceUnitCode = cookingFlowParserPieceUnitCode;
const int _cookingFuzzyInstructionMatchThreshold = 90;
const int _maxCookingFuzzyInstructionSpanTokens = 3;
