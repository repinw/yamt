import 'package:yamt/features/inventory/domain/global_food_item.dart';

enum GlobalFoodMatchReason { fingerprintExact, nameBrandStrong, nameTokenMatch }

class GlobalFoodMatchCandidate {
  const GlobalFoodMatchCandidate({
    required this.item,
    required this.score,
    required this.reason,
  });

  final GlobalFoodItem item;
  final double score;
  final GlobalFoodMatchReason reason;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalFoodMatchCandidate &&
            other.item == item &&
            other.score == score &&
            other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(item, score, reason);
}
