import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/inventory/domain/eat_amount_step.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

/// Ruler range of an entry amount in grams or milliliters.
const _rulerRange = 1000.0;

/// A logged entry moved to another meal or day: the entry before the move
/// and the moved one to save.
typedef DiaryEntryMove = ({CalorieEntry previous, CalorieEntry updated});

/// State of the diary entry details page: the logged entry and the amount
/// typed on the ruler, which saves only on confirm.
@immutable
class DiaryEntryDetailsState {
  /// Creates the state.
  const new({
    required this.entry,
    required this.amountText,
    required this.today,
  });

  /// The logged entry as stored, or as a move is saving it.
  final CalorieEntry entry;

  /// Text of the amount field.
  final String amountText;

  /// The current day, the last one an entry can move to.
  final DateTime today;

  /// Whether the eaten amount can change. A bundle counts portions of a meal
  /// or several foods, so it shows its amount only.
  bool get canEditAmount => canEditCalorieEntryAmount(entry);

  /// The entered amount, or null when it is not a number above zero.
  double? get amount => parsePositiveDecimalInput(amountText);

  /// Whether the entered amount cannot be saved.
  bool get hasAmountError => canEditAmount && amount == null;

  /// Amount to save, or null when the entered amount is the stored one or
  /// not valid.
  ///
  /// The field shows the stored amount rounded, so its unchanged text means
  /// the stored amount.
  double? get changedAmount {
    final entered = amount;
    if (!canEditAmount ||
        entered == null ||
        entered == entry.consumedAmount ||
        amountText == diaryEntryAmountText(entry.consumedAmount)) {
      return null;
    }
    return entered;
  }

  /// [entry] with its totals at the entered amount, as saving would store
  /// it.
  CalorieEntry get preview {
    final changed = changedAmount;
    if (changed == null) {
      return entry;
    }
    return rescaleCalorieEntry(entry, amount: changed, now: entry.updatedAt);
  }

  /// Largest amount on the ruler.
  double get rulerMax {
    return math.max(_rulerRange, (entry.consumedAmount * 2).ceilToDouble());
  }

  /// Step the ruler snaps to.
  double get rulerStep => eatAmountStep(rulerMax).toDouble();

  /// Ruler position of the entered amount.
  double get rulerValue => math.min(amount ?? 0, rulerMax);

  /// Copy with the given fields replaced.
  DiaryEntryDetailsState copyWith({CalorieEntry? entry, String? amountText}) {
    return DiaryEntryDetailsState(
      entry: entry ?? this.entry,
      amountText: amountText ?? this.amountText,
      today: today,
    );
  }
}

/// Text of [amount] in the amount field, with at most two decimals and no
/// trailing zeros.
String diaryEntryAmountText(double amount) {
  final fixed = amount.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
