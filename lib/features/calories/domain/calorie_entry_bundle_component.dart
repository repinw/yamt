import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_entry_bundle_component.g.dart';

/// Defines calorie entry bundle component.
@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieEntryBundleComponent {
  /// The calorie entry bundle component.
  const new({
    required this.name,
    required this.amountLabel,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.brand,
    this.imageUrl,
    this.sourceInventoryItemId,
    this.sourceInventoryAmountToRestore,
  });

  /// Creates a [CalorieEntryBundleComponent] for from json.
  factory fromJson(Map<String, dynamic> json) {
    return _$CalorieEntryBundleComponentFromJson(json);
  }

  /// The name.
  final String name;

  /// The amount label.
  final String amountLabel;

  /// The brand.
  final String? brand;

  /// The image url.
  final String? imageUrl;

  /// Stock item the component was eaten from, in a combined entry.
  final String? sourceInventoryItemId;

  /// Stock amount that deleting a combined entry can return to
  /// [sourceInventoryItemId].
  final int? sourceInventoryAmountToRestore;

  /// Whether deleting the entry can return this component's stock.
  bool get canRestoreToInventory {
    return (sourceInventoryItemId?.trim().isNotEmpty ?? false) &&
        (sourceInventoryAmountToRestore ?? 0) > 0;
  }

  /// The total kcal.
  @FlexibleDoubleConverter()
  final double totalKcal;

  /// The total protein.
  @FlexibleDoubleConverter()
  final double totalProtein;

  /// The total carbs.
  @FlexibleDoubleConverter()
  final double totalCarbs;

  /// The total fat.
  @FlexibleDoubleConverter()
  final double totalFat;

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieEntryBundleComponentToJson(this);

  /// Copy with.
  CalorieEntryBundleComponent copyWith({
    String? name,
    String? amountLabel,
    String? brand,
    String? imageUrl,
    double? totalKcal,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
  }) {
    return CalorieEntryBundleComponent(
      name: name ?? this.name,
      amountLabel: amountLabel ?? this.amountLabel,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      sourceInventoryItemId: sourceInventoryItemId,
      sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
    );
  }
}
