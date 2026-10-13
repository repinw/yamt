import 'package:meta/meta.dart';
import 'package:yamt/core/utils/flexible_decimal_parser.dart';

/// The most grams a typed weight of a meal may have, as on the "Gekocht"
/// scale field.
const preparedMealMaxWeight = 99999;

/// A weight typed for the food of a cooked meal: the pot with the food on
/// the scale when the meal knows its empty pot, otherwise the food alone.
///
/// The weight counts in whole grams. A decimal comma or point is rounded,
/// and "1.250" reads as 1250 g.
@immutable
class PreparedMealWeightEntry {
  /// Reads [text], with the empty pot's [tareWeight] when the pot is on the
  /// scale.
  const new(this.text, {this.tareWeight});

  /// The typed weight.
  final String text;

  /// Grams of the empty pot, or null when the food is weighed alone.
  final int? tareWeight;

  /// The typed weight in whole grams, or null when it is no weight from 1
  /// to [preparedMealMaxWeight] grams.
  int? get scaleWeight {
    final parsed = parseFlexibleDecimal(text);
    if (parsed == null || !parsed.isFinite) {
      return null;
    }
    final grams = parsed.round();
    return grams >= 1 && grams <= preparedMealMaxWeight ? grams : null;
  }

  /// Grams of food: the scale minus the empty pot. Null without a weight or
  /// when the scale shows no more than the empty pot.
  int? get netWeight {
    final scale = scaleWeight;
    if (scale == null) {
      return null;
    }
    final net = scale - (tareWeight ?? 0);
    return net >= 1 ? net : null;
  }

  /// Whether the scale shows a weight, but no more than the empty pot.
  bool get isTooLight => scaleWeight != null && netWeight == null;

  /// Whether something is typed that is no weight.
  bool get isInvalid => text.trim().isNotEmpty && scaleWeight == null;
}
