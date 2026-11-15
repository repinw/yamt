import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

part 'cook_run_line.g.dart';

/// Where a line of a cook run comes from.
enum CookLineOrigin {
  /// A line of the recipe.
  recipe,

  /// Added while assigning ("+ Zutat").
  added,

  /// Spoken or typed in while cooking.
  cooking,
}

/// How many grams or ml one piece of a recipe line weighs, copied from the
/// recipe. The stored form matches the recipe's own conversion.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: true,
)
class CookLineConversion {
  /// Creates the conversion.
  const new({required this.amountPerPiece, required this.unit});

  /// Reads a conversion.
  factory fromJson(Map<String, dynamic> json) =>
      _$CookLineConversionFromJson(json);

  /// The amount of one piece in [unit].
  @JsonKey(required: true)
  final int amountPerPiece;

  /// The unit of [amountPerPiece].
  @JsonKey(required: true, fromJson: _readUnit, toJson: _writeUnit)
  final TemplateIngredientUnit unit;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookLineConversionToJson(this);

  @override
  bool operator ==(Object other) =>
      other is CookLineConversion &&
      other.amountPerPiece == amountPerPiece &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(amountPerPiece, unit);
}

/// The recipe's rough weight of a whole line whose text names no amount,
/// such as 20 g for "Butter zum Braten", for the run's base portions.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: true,
)
class CookRoughWeight {
  /// Creates the weight.
  const new({required this.amount, required this.unit});

  /// Reads a weight.
  factory fromJson(Map<String, dynamic> json) =>
      _$CookRoughWeightFromJson(json);

  /// The amount in [unit], above 0.
  @JsonKey(required: true)
  final int amount;

  /// Grams or milliliters.
  @JsonKey(required: true, fromJson: _readWeightUnit, toJson: _writeUnit)
  final TemplateIngredientUnit unit;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookRoughWeightToJson(this);

  @override
  bool operator ==(Object other) =>
      other is CookRoughWeight && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);
}

TemplateIngredientUnit _readUnit(String code) =>
    TemplateIngredientUnit.values.firstWhere(
      (unit) => unit.code == code,
      orElse: () => throw FormatException('Unknown unit: $code'),
    );

// Grams or milliliters only: a rough weight is never in pieces.
TemplateIngredientUnit _readWeightUnit(String code) =>
    switch (_readUnit(code)) {
      TemplateIngredientUnit.piece => throw FormatException(
        'Not a weight unit: $code',
      ),
      final unit => unit,
    };

String _writeUnit(TemplateIngredientUnit unit) => unit.code;

TemplateIngredientUnit? _readOptionalUnit(String? code) =>
    code == null ? null : _readUnit(code);

String? _writeOptionalUnit(TemplateIngredientUnit? unit) => unit?.code;

/// One line of a cook run, identified by [id] for as long as the run lasts.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  disallowUnrecognizedKeys: true,
)
class CookRunLine {
  /// Creates a line.
  const new({
    required this.id,
    required this.text,
    required this.origin,
    required this.conversion,
    required this.amount,
    required this.amountPortions,
    required this.amountUnit,
    required this.settlement,
    required this.weighed,
    required this.potId,
    required this.addedItemIds,
    this.roughWeight,
  });

  /// Reads a line. Throws a [FormatException] when only one of [amount]
  /// and [amountPortions] is set, [amountPortions] is below 1, or
  /// [amountUnit] is set without [amount].
  factory fromJson(Map<String, dynamic> json) {
    final line = _$CookRunLineFromJson(json);
    final portions = line.amountPortions;
    if ((line.amount == null) != (portions == null) ||
        (portions != null && portions < 1) ||
        (line.amount == null && line.amountUnit != null)) {
      throw FormatException(
        'Cook run line ${line.id} has amount ${line.amount} '
        '${line.amountUnit} for $portions portions.',
      );
    }
    return line;
  }

  /// `line-<index>` of the recipe line, a uuid for a new line.
  @JsonKey(required: true)
  final String id;

  /// The line as the recipe or the cook wrote it, not scaled.
  @JsonKey(required: true)
  final String text;

  /// Where the line comes from.
  @JsonKey(required: true)
  final CookLineOrigin origin;

  /// The recipe's piece weight of the line, `null` without one.
  @JsonKey(required: true)
  final CookLineConversion? conversion;

  /// The cook's amount in the line's unit, for [amountPortions] portions;
  /// `null` means the recipe's amount, scaled to the portions.
  @JsonKey(required: true)
  final int? amount;

  /// The run's portions when the cook set [amount]; `null` exactly when
  /// [amount] is. The amount scales from these to the run's portions.
  @JsonKey(required: true)
  final int? amountPortions;

  /// The unit of [amount] on a line whose text names none, as the cook saw it
  /// when typing it: so 3 eggs stay 3 pieces when the line leaves its item.
  /// `null` when the text names the unit, or from before the unit was stored.
  @JsonKey(
    includeIfNull: false,
    fromJson: _readOptionalUnit,
    toJson: _writeOptionalUnit,
  )
  final TemplateIngredientUnit? amountUnit;

  /// How the line is settled.
  @JsonKey(required: true)
  final LineSettlement settlement;

  /// What the cook weighed, in grams or ml.
  @JsonKey(required: true)
  final int? weighed;

  /// The pot the line goes into when the run has two pots or more; `null`
  /// means the first pot.
  @JsonKey(required: true)
  final String? potId;

  /// Items that search, barcode or AI put into the Vorrat for this line.
  @JsonKey(required: true)
  final List<String> addedItemIds;

  /// The recipe's rough weight of a recipe line whose text names no amount;
  /// the line needs it, scaled to the portions, until the cook sets an
  /// amount. `null` on every other line.
  @JsonKey(includeIfNull: false)
  final CookRoughWeight? roughWeight;

  /// The stored form.
  Map<String, dynamic> toJson() => _$CookRunLineToJson(this);

  /// A copy with the given fields replaced. A nullable field takes a
  /// function, so it can become `null`.
  CookRunLine copyWith({
    LineSettlement? settlement,
    int? Function()? amount,
    int? Function()? amountPortions,
    TemplateIngredientUnit? Function()? amountUnit,
    int? Function()? weighed,
    String? Function()? potId,
    List<String>? addedItemIds,
  }) => CookRunLine(
    id: id,
    text: text,
    origin: origin,
    conversion: conversion,
    amount: amount == null ? this.amount : amount(),
    amountPortions: amountPortions == null
        ? this.amountPortions
        : amountPortions(),
    amountUnit: amountUnit == null ? this.amountUnit : amountUnit(),
    settlement: settlement ?? this.settlement,
    weighed: weighed == null ? this.weighed : weighed(),
    potId: potId == null ? this.potId : potId(),
    addedItemIds: addedItemIds ?? this.addedItemIds,
    roughWeight: roughWeight,
  );

  List<Object?> get _props => [
    id,
    text,
    origin,
    conversion,
    amount,
    amountPortions,
    amountUnit,
    settlement,
    weighed,
    potId,
    addedItemIds,
    roughWeight,
  ];

  @override
  bool operator ==(Object other) =>
      other is CookRunLine &&
      const DeepCollectionEquality().equals(other._props, _props);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_props);
}

/// The id of the line that holds on the shopping list what the line [lineId]
/// lacks ("200 ml kaufen" when only 300 of 500 ml are there). It waits there
/// as [CookLineOrigin.added] with `LineShopping`.
String cookRestLineId(String lineId) => '$lineId-rest';
