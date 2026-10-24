import 'dart:math' as math;

import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';

/// Piece, portion and package math of the eat page, in inventory units.
extension InventoryItemEatAmounts on InventoryItemEatCalculator {
  /// Size of one package: the calculator's package, else the product's
  /// package weight in the stock unit, or null without one.
  int? get packageSize {
    if (packageAmount case final package?) {
      return package;
    }
    final parsed = const InventoryAmountParser().tryParse(
      rawWeight: item.weight,
      quantity: 1,
    );
    return parsed?.unit == inventoryAmountUnit && inventoryAmountScale == 1
        ? parsed!.amount
        : null;
  }

  /// [count] pieces in inventory units. A count over the stock is all of
  /// it, so rounding never takes more than is left.
  int stockAmountOfPieces(double count) {
    return math.min(count * inventoryAmountScale, maxAmount.toDouble()).round();
  }

  /// Most pieces the stock holds.
  double get maxPieces => maxAmount / inventoryAmountScale;

  /// Most portions of [weight] the stock holds; 1 without a weight.
  double maxPortionsOf(double weight) {
    return weight <= 0 ? 1 : maxAmount / weight;
  }

  /// [value] snapped to half portions of [portion], at least one half and
  /// at most what the stock holds.
  double halfPortionAmount(double value, double portion) {
    final half = portion / 2;
    final halves = math.min(
      math.max(1, (value / half).round()),
      (maxAmount / half).floor(),
    );
    return halves * half;
  }

  /// [amount] moved to the next whole portion of [size] up, or down when
  /// [up] is false, or null when the stock has no room. Never below zero.
  double? steppedPortionAmount(double amount, double size, {required bool up}) {
    final count = amount / size;
    final next = up
        ? ((count + 0.001).floor() + 1) * size
        : math.max(0, (count - 0.001).ceil() - 1) * size;
    return next > maxAmount ? null : next;
  }

  /// Number of whole packages in [amount], or null when the item has no
  /// package to count.
  int? packageCountOf(double amount) {
    final package = packageAmount;
    return package == null ? null : ((amount + 0.001) / package).floor();
  }

  /// [amount] moved to the next whole package up, or down when [up] is
  /// false, or null when the item has no package to count. Never below
  /// zero.
  int? steppedPackageAmount(double amount, {required bool up}) {
    final package = packageAmount;
    if (package == null) {
      return null;
    }
    final next = up
        ? ((amount + 0.001) / package).floor() + 1
        : math.max(0, ((amount - 0.001) / package).ceil() - 1);
    return next * package;
  }
}

/// Whether [count] portions of [portion] still give [amount]: the amount is
/// unset, or the count's amount is within the rounding of a one-decimal
/// weight.
bool portionCountGivesAmount({
  required double count,
  required double portion,
  required double amount,
}) {
  return amount == 0 || (count * portion - amount).abs() <= 0.05 + 0.001;
}
