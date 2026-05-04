import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_product_lookup_models.g.dart';

/// Defines calorie product source.
@JsonEnum(valueField: 'jsonValue')
enum CalorieProductSource {
  /// User override.
  userOverride('user_override'),

  /// Global catalog.
  globalCatalog('global_catalog'),

  /// Off barcode.
  offBarcode('off_barcode'),

  /// Off search.
  offSearch('off_search'),

  /// Ocr.
  ocr('ocr')
  ;

  const CalorieProductSource(this.jsonValue);

  /// The json value.
  final String jsonValue;
}

/// Defines calorie product profile.
@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieProductProfile {
  /// The calorie product profile.
  const CalorieProductProfile({
    required this.barcode,
    required this.name,
    required this.per100Kcal,
    required this.per100Protein,
    required this.per100Carbs,
    required this.per100Fat,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.offProductId,
    this.imageUrl,
  });

  /// Creates a [CalorieProductProfile] for from json.
  factory CalorieProductProfile.fromJson(Map<String, dynamic> json) {
    return _$CalorieProductProfileFromJson(json);
  }

  /// Creates a [CalorieProductProfile] for from entry.
  factory CalorieProductProfile.fromEntry({
    required CalorieEntry entry,
    required String barcode,
    required CalorieProductSource source,
    required String? offProductId,
    required String? imageUrl,
    required DateTime now,
  }) {
    return CalorieProductProfile(
      barcode: barcode,
      name: entry.name.trim(),
      brand: entry.brand?.trim().isEmpty == true ? null : entry.brand?.trim(),
      per100Kcal: entry.per100Kcal,
      per100Protein: entry.per100Protein,
      per100Carbs: entry.per100Carbs,
      per100Fat: entry.per100Fat,
      source: source,
      offProductId: offProductId,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// The barcode.
  final String barcode;

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The per100 kcal.
  @FlexibleDoubleConverter()
  final double per100Kcal;

  /// The per100 protein.
  @FlexibleDoubleConverter()
  final double per100Protein;

  /// The per100 carbs.
  @FlexibleDoubleConverter()
  final double per100Carbs;

  /// The per100 fat.
  @FlexibleDoubleConverter()
  final double per100Fat;

  /// The source.
  final CalorieProductSource source;

  /// The off product id.
  final String? offProductId;

  /// The image url.
  final String? imageUrl;

  /// The created at.
  @FlexibleDateTimeConverter()
  final DateTime createdAt;

  /// The updated at.
  @FlexibleDateTimeConverter()
  final DateTime updatedAt;

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieProductProfileToJson(this);

  /// Copy with.
  CalorieProductProfile copyWith({
    String? barcode,
    String? name,
    String? brand,
    double? per100Kcal,
    double? per100Protein,
    double? per100Carbs,
    double? per100Fat,
    CalorieProductSource? source,
    String? offProductId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalorieProductProfile(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      per100Kcal: per100Kcal ?? this.per100Kcal,
      per100Protein: per100Protein ?? this.per100Protein,
      per100Carbs: per100Carbs ?? this.per100Carbs,
      per100Fat: per100Fat ?? this.per100Fat,
      source: source ?? this.source,
      offProductId: offProductId ?? this.offProductId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Defines calorie scanned source ref.
class CalorieScannedSourceRef {
  /// The calorie scanned source ref.
  const CalorieScannedSourceRef({
    required this.barcode,
    required this.source,
    this.offProductId,
  });

  /// The barcode.
  final String barcode;

  /// The source.
  final CalorieProductSource source;

  /// The off product id.
  final String? offProductId;
}
