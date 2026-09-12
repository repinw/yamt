import 'package:meta/meta.dart';

/// Localized labels needed by the instruction builder.
@immutable
class CookingFlowInstructionText {
  /// Creates localized instruction builder text.
  const CookingFlowInstructionText({
    required this.unknownAmount,
    required this.fallbackNoIngredients,
    required this.fallbackPrepPrefix,
    required this.fallbackCookText,
    this.pieceUnit = '',
  });

  /// Unknown amount label.
  final String unknownAmount;

  /// Fallback line when no ingredients exist.
  final String fallbackNoIngredients;

  /// Fallback prep line prefix.
  final String fallbackPrepPrefix;

  /// Fallback cooking line.
  final String fallbackCookText;

  /// Localized piece unit label, e.g. 'Stück' or 'Piece'.
  final String pieceUnit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingFlowInstructionText &&
            other.unknownAmount == unknownAmount &&
            other.fallbackNoIngredients == fallbackNoIngredients &&
            other.fallbackPrepPrefix == fallbackPrepPrefix &&
            other.fallbackCookText == fallbackCookText &&
            other.pieceUnit == pieceUnit;
  }

  @override
  int get hashCode => Object.hash(
    unknownAmount,
    fallbackNoIngredients,
    fallbackPrepPrefix,
    fallbackCookText,
    pieceUnit,
  );

  @override
  String toString() {
    return 'CookingFlowInstructionText('
        'unknownAmount: "$unknownAmount", '
        'fallbackNoIngredients: "$fallbackNoIngredients", '
        'pieceUnit: "$pieceUnit")';
  }
}

/// Cookflow instruction step with highlighted ingredient segments.
@immutable
class CookingFlowInstructionStep {
  /// Creates instruction step.
  const CookingFlowInstructionStep({required this.segments});

  /// Rich-text segments for this instruction.
  final List<CookingFlowInstructionSegment> segments;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingFlowInstructionStep &&
            _segmentsEqual(other.segments, segments);
  }

  @override
  int get hashCode => Object.hashAll(segments);

  @override
  String toString() => 'CookingFlowInstructionStep(segments: $segments)';
}

/// Segment inside one instruction line.
@immutable
class CookingFlowInstructionSegment {
  /// Creates instruction segment.
  const CookingFlowInstructionSegment(this.text, {this.isHighlight = false});

  /// Segment text.
  final String text;

  /// Whether segment should be highlighted.
  final bool isHighlight;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingFlowInstructionSegment &&
            other.text == text &&
            other.isHighlight == isHighlight;
  }

  @override
  int get hashCode => Object.hash(text, isHighlight);

  @override
  String toString() =>
      'CookingFlowInstructionSegment("$text", isHighlight: $isHighlight)';
}

/// Match candidate inside instruction text.
@immutable
class CookingInstructionMatch {
  /// Creates an instruction match span.
  const CookingInstructionMatch({
    required this.start,
    required this.end,
    required this.label,
  });

  /// Start index in source instruction.
  final int start;

  /// End index in source instruction.
  final int end;

  /// Replacement text label for this match.
  final String label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingInstructionMatch &&
            other.start == start &&
            other.end == end &&
            other.label == label;
  }

  @override
  int get hashCode => Object.hash(start, end, label);

  @override
  String toString() => 'CookingInstructionMatch($start..$end, label: "$label")';
}

bool _segmentsEqual(
  List<CookingFlowInstructionSegment> a,
  List<CookingFlowInstructionSegment> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
