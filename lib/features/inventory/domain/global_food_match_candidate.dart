import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Defines global food match reason.
enum GlobalFoodMatchReason {
  /// Documented member.
  receiptAliasExact,

  /// Documented member.
  fingerprintExact,

  /// Documented member.
  nameExact,

  /// Documented member.
  nameBrandStrong,

  /// Documented member.
  nameTokenMatch,

  /// Documented member.
  externalSearch,
}

/// Defines global food match candidate.
class GlobalFoodMatchCandidate {
  /// The global food match candidate.
  const GlobalFoodMatchCandidate({
    required this.item,
    required this.score,
    required this.reason,
    this.requiresPersistence = false,
  });

  /// The item.
  final GlobalFoodItem item;

  /// The score.
  final double score;

  /// The reason.
  final GlobalFoodMatchReason reason;

  /// The requires persistence.
  final bool requiresPersistence;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalFoodMatchCandidate &&
            other.item == item &&
            other.score == score &&
            other.reason == reason &&
            other.requiresPersistence == requiresPersistence;
  }

  @override
  int get hashCode => Object.hash(item, score, reason, requiresPersistence);
}
