import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'cook_line_settlement.g.dart';

/// Part of one Vorrat item that supplies a line: [amount] in the unit and
/// scale of the item. A line without an amount, such as "Salz", takes 0.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: true,
)
class ItemTake {
  /// Creates a take.
  const new({required this.itemId, required this.amount});

  /// Reads a take.
  factory fromJson(Map<String, dynamic> json) => _$ItemTakeFromJson(json);

  /// The Vorrat item.
  @JsonKey(required: true)
  final String itemId;

  /// What the line takes from the item.
  @JsonKey(required: true)
  final int amount;

  /// The stored form.
  Map<String, dynamic> toJson() => _$ItemTakeToJson(this);

  @override
  bool operator ==(Object other) =>
      other is ItemTake && other.itemId == itemId && other.amount == amount;

  @override
  int get hashCode => Object.hash(itemId, amount);
}

/// How a line of a cook run is settled.
@immutable
sealed class LineSettlement {
  /// Creates the settlement.
  const new();

  /// Reads a settlement. Throws a [FormatException] for an unknown `type`
  /// or a field too many or too few.
  factory fromJson(Map<String, dynamic> json) => switch (json) {
    {'type': 'open'} when json.length == 1 => const LineOpen(),
    {'type': 'assigned', 'takes': final List<dynamic> takes}
        when json.length == 2 =>
      LineAssigned([
        for (final take in takes)
          ItemTake.fromJson(take as Map<String, dynamic>),
      ]),
    {'type': 'shopping'} when json.length == 1 => const LineShopping(),
    {'type': 'ignored'} when json.length == 1 => const LineIgnored(),
    _ => throw FormatException('Unknown line settlement: $json'),
  };

  /// The stored form, tagged with `type`.
  Map<String, dynamic> toJson();
}

/// Not settled yet.
final class LineOpen extends LineSettlement {
  /// Creates the open settlement.
  const new();

  @override
  Map<String, dynamic> toJson() => {'type': 'open'};

  @override
  bool operator ==(Object other) => other is LineOpen;

  @override
  int get hashCode => (LineOpen).hashCode;
}

/// Supplied from the Vorrat by [takes], first item first. Each item appears
/// at most once, so what a line takes from one item is in one place.
final class LineAssigned extends LineSettlement {
  /// Creates the settlement. Throws an [ArgumentError] for no takes, a
  /// negative amount or an item that appears twice.
  new(List<ItemTake> takes) : takes = List.unmodifiable(takes) {
    if (takes.isEmpty) {
      throw ArgumentError.value(takes, 'takes', 'must not be empty');
    }
    if (takes.any((take) => take.amount < 0)) {
      throw ArgumentError.value(takes, 'takes', 'must not be negative');
    }
    if (takes.map((take) => take.itemId).toSet().length != takes.length) {
      throw ArgumentError.value(takes, 'takes', 'must name each item once');
    }
  }

  /// What the line takes, item by item.
  final List<ItemTake> takes;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'assigned',
    'takes': [for (final take in takes) take.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is LineAssigned &&
      const ListEquality<ItemTake>().equals(other.takes, takes);

  @override
  int get hashCode => const ListEquality<ItemTake>().hash(takes);
}

/// Goes on the shopping list; the cook run pauses for it.
final class LineShopping extends LineSettlement {
  /// Creates the shopping settlement.
  const new();

  @override
  Map<String, dynamic> toJson() => {'type': 'shopping'};

  @override
  bool operator ==(Object other) => other is LineShopping;

  @override
  int get hashCode => (LineShopping).hashCode;
}

/// Stays in the recipe but takes nothing, is not weighed and does not
/// count in the nutrition, such as salt and pepper.
final class LineIgnored extends LineSettlement {
  /// Creates the ignored settlement.
  const new();

  @override
  Map<String, dynamic> toJson() => {'type': 'ignored'};

  @override
  bool operator ==(Object other) => other is LineIgnored;

  @override
  int get hashCode => (LineIgnored).hashCode;
}
