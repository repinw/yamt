import 'package:yamt/features/cooking/domain/cook_session.dart';

/// What one Vorrat item can still give: `available` in its unit.
typedef StockOffer = ({String itemId, int available});

/// Fills [needed] from [offers] in their order: each item gives what it
/// has, the last one only the rest. Items that are not needed any more are
/// left out. A [needed] of 0 (a line without amount) takes the first item
/// with nothing.
List<ItemTake> fillInOrder({
  required int needed,
  required List<StockOffer> offers,
}) {
  if (needed <= 0) {
    return [
      for (final offer in offers.take(1)) (itemId: offer.itemId, amount: 0),
    ];
  }
  final takes = <ItemTake>[];
  var rest = needed;
  for (final offer in offers) {
    if (rest <= 0) break;
    if (offer.available <= 0) continue;
    final amount = offer.available < rest ? offer.available : rest;
    takes.add((itemId: offer.itemId, amount: amount));
    rest -= amount;
  }
  return takes;
}

/// The sum of [takes].
int takenAmount(List<ItemTake> takes) =>
    takes.fold(0, (sum, take) => sum + take.amount);
