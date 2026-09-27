import 'package:yamt/core/utils/flexible_decimal_parser.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Parses decimals, simple fractions, and mixed fractions.
double? parseCookingFlowQuantity(String rawValue) {
  final normalized = rawValue.trim();
  final mixedFractionMatch = RegExp(r'^(\d+)\s+(\d+)/(\d+)$')
      .firstMatch(normalized);
  if (mixedFractionMatch != null) {
    final whole = _parseCookingFlowNumber(mixedFractionMatch.group(1)!);
    final numerator = _parseCookingFlowNumber(mixedFractionMatch.group(2)!);
    final denominator = _parseCookingFlowNumber(mixedFractionMatch.group(3)!);
    if (whole == null ||
        numerator == null ||
        denominator == null ||
        denominator == 0) {
      return null;
    }
    return whole + numerator / denominator;
  }
  if (normalized.contains('/')) {
    final parts = normalized.split('/');
    if (parts.length != 2) {
      return null;
    }
    final numerator = _parseCookingFlowNumber(parts[0]);
    final denominator = _parseCookingFlowNumber(parts[1]);
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
  return _parseCookingFlowNumber(normalized);
}

double? _parseCookingFlowNumber(String value) {
  return parseFlexibleDecimal(value);
}

/// Formats a decimal amount without trailing zero noise.
String formatCookingFlowDecimal(num value) {
  final d = value.toDouble();
  if (d == d.roundToDouble()) {
    return d.round().toString();
  }
  return d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}

/// Scales [amount] from [basePortions] to [targetPortions], returning
/// [amount] unchanged when portions are invalid or equal.
double scaleCookingFlowAmount(
  double amount, {
  required int targetPortions,
  required int basePortions,
}) {
  if (targetPortions < 1 ||
      basePortions < 1 ||
      targetPortions == basePortions) {
    return amount;
  }
  return amount * targetPortions / basePortions;
}

/// Formats a scaled amount range label (for example "1-2" scaled by 2
/// becomes "2-4"), falling back to the raw range text when either bound
/// cannot be parsed or portions are invalid or equal.
String formatScaledCookingFlowRangeLabel({
  required String startRaw,
  required String endRaw,
  required int targetPortions,
  required int basePortions,
}) {
  if (targetPortions < 1 ||
      basePortions < 1 ||
      targetPortions == basePortions) {
    return '$startRaw-$endRaw';
  }
  final startAmount = parseCookingFlowQuantity(startRaw);
  final endAmount = parseCookingFlowQuantity(endRaw);
  if (startAmount == null || endAmount == null) {
    return '$startRaw-$endRaw';
  }
  final scaledStart = scaleCookingFlowAmount(
    startAmount,
    targetPortions: targetPortions,
    basePortions: basePortions,
  ).round();
  final scaledEnd = scaleCookingFlowAmount(
    endAmount,
    targetPortions: targetPortions,
    basePortions: basePortions,
  ).round();
  return '$scaledStart-$scaledEnd';
}

/// Normalizes unicode vulgar fractions to ascii fractions.
String normalizeCookingFractions(String value) {
  return value
      .replaceAll('½', '1/2')
      .replaceAll('¼', '1/4')
      .replaceAll('¾', '3/4')
      .replaceAll('⅓', '1/3')
      .replaceAll('⅔', '2/3')
      .replaceAll('⅛', '1/8')
      .replaceAll('⅜', '3/8')
      .replaceAll('⅝', '5/8')
      .replaceAll('⅞', '7/8');
}

/// Strips prefix qualifiers like 'ca.' or 'etwa' from ingredient descriptions.
String stripCookingPrefixQualifiers(String value) {
  return value
      .replaceFirst(
        RegExp(
          r'^(?:ca\.?|circa|approx\.?|etwa|rund)(?:\s+|$)',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
}

/// Cleans ingredient names by removing parenthetical clauses and trailing
/// details.
String cleanIngredientReferenceName(String name) {
  var cleaned = name.trim();
  cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
  final commaIndex = cleaned.indexOf(',');
  if (commaIndex > 0) {
    cleaned = cleaned.substring(0, commaIndex).trim();
  }
  return cleaned.isNotEmpty ? cleaned : name.trim();
}

/// Formats amount label from a structured template requirement.
String cookflowCookingRequirementAmountLabel({
  required TemplateIngredientRequirement requirement,
  required String pieceUnitLabel,
}) {
  final packageCountLabel = requirement.packageCountLabel?.trim();
  if (packageCountLabel?.isNotEmpty == true &&
      requirement.unit.code != cookingFlowParserPieceUnitCode) {
    return '$packageCountLabel ${requirement.amount}${requirement.unit.code}';
  }
  final countMeasureLabel = requirement.countMeasureLabel?.trim();
  if (countMeasureLabel?.isNotEmpty == true) {
    return '${requirement.amount} $countMeasureLabel';
  }
  if (requirement.unit.code == cookingFlowParserPieceUnitCode) {
    if (pieceUnitLabel.isNotEmpty) {
      return '${requirement.amount} $pieceUnitLabel';
    }
    return requirement.amount.toString();
  }
  return '${requirement.amount} ${requirement.unit.code}';
}
