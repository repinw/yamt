import 'package:yamt/features/inventory/domain/global_food_item.dart';

enum GlobalFoodMatchReason {
  receiptAliasExact,
  fingerprintExact,
  nameExact,
  nameBrandStrong,
  nameTokenMatch,
  externalSearch,
}

class GlobalFoodMatchCandidate {
  const GlobalFoodMatchCandidate({
    required this.item,
    required this.score,
    required this.reason,
    this.requiresPersistence = false,
  });

  final GlobalFoodItem item;
  final double score;
  final GlobalFoodMatchReason reason;
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
