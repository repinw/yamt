import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_product_lookup_models.g.dart';

@JsonEnum(valueField: 'jsonValue')
enum CalorieProductSource {
  userOverride('user_override'),
  globalCatalog('global_catalog'),
  offBarcode('off_barcode'),
  offSearch('off_search'),
  ocr('ocr');

  const CalorieProductSource(this.jsonValue);

  final String jsonValue;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieProductProfile {
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

  final String barcode;
  final String name;
  final String? brand;
  @FlexibleDoubleConverter()
  final double per100Kcal;
  @FlexibleDoubleConverter()
  final double per100Protein;
  @FlexibleDoubleConverter()
  final double per100Carbs;
  @FlexibleDoubleConverter()
  final double per100Fat;
  final CalorieProductSource source;
  final String? offProductId;
  final String? imageUrl;
  @FlexibleDateTimeConverter()
  final DateTime createdAt;
  @FlexibleDateTimeConverter()
  final DateTime updatedAt;

  factory CalorieProductProfile.fromJson(Map<String, dynamic> json) {
    return _$CalorieProductProfileFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieProductProfileToJson(this);

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
}

class CalorieProductCandidate {
  const CalorieProductCandidate({
    required this.profile,
    required this.completenessScore,
  });

  final CalorieProductProfile profile;
  final int completenessScore;
}

class CalorieNutritionOcrDraft {
  const CalorieNutritionOcrDraft({
    required this.barcode,
    this.name,
    this.brand,
    this.quantityLabel,
    this.servingSizeLabel,
    this.per100Kcal,
    this.per100Protein,
    this.per100Carbs,
    this.per100Fat,
    this.per100Salt,
    this.per100SaturatedFat,
    this.per100PolyunsaturatedFat,
    this.per100Sugar,
    this.per100Fiber,
  });

  final String barcode;
  final String? name;
  final String? brand;
  final String? quantityLabel;
  final String? servingSizeLabel;
  final double? per100Kcal;
  final double? per100Protein;
  final double? per100Carbs;
  final double? per100Fat;
  final double? per100Salt;
  final double? per100SaturatedFat;
  final double? per100PolyunsaturatedFat;
  final double? per100Sugar;
  final double? per100Fiber;

  bool get hasAnyNutritionValue {
    return <double?>[
      per100Kcal,
      per100Protein,
      per100Carbs,
      per100Fat,
      per100Salt,
      per100SaturatedFat,
      per100PolyunsaturatedFat,
      per100Sugar,
      per100Fiber,
    ].any((value) => value != null);
  }

  bool get hasAnyDetectedValue {
    return hasAnyNutritionValue ||
        _hasText(name) ||
        _hasText(brand) ||
        _hasText(quantityLabel) ||
        _hasText(servingSizeLabel);
  }

  CalorieProductProfile? toProfile({required DateTime now}) {
    if (per100Kcal == null ||
        per100Protein == null ||
        per100Carbs == null ||
        per100Fat == null) {
      return null;
    }

    return CalorieProductProfile(
      barcode: barcode,
      name: _normalizedText(name) ?? barcode,
      brand: _normalizedText(brand),
      per100Kcal: per100Kcal!,
      per100Protein: per100Protein!,
      per100Carbs: per100Carbs!,
      per100Fat: per100Fat!,
      source: CalorieProductSource.ocr,
      offProductId: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  static bool _hasText(String? value) {
    return _normalizedText(value) != null;
  }

  static String? _normalizedText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

enum CalorieLookupStatus { foundSingle, foundMultiple, notFound, failed }

class CalorieLookupOutcome {
  const CalorieLookupOutcome._({
    required this.status,
    this.product,
    this.candidates = const <CalorieProductCandidate>[],
    this.errorCode,
  });

  final CalorieLookupStatus status;
  final CalorieProductProfile? product;
  final List<CalorieProductCandidate> candidates;
  final String? errorCode;

  const CalorieLookupOutcome.foundSingle(CalorieProductProfile product)
    : this._(status: CalorieLookupStatus.foundSingle, product: product);

  const CalorieLookupOutcome.foundMultiple(
    List<CalorieProductCandidate> candidates,
  ) : this._(status: CalorieLookupStatus.foundMultiple, candidates: candidates);

  const CalorieLookupOutcome.notFound()
    : this._(status: CalorieLookupStatus.notFound);

  const CalorieLookupOutcome.failed({required String errorCode})
    : this._(status: CalorieLookupStatus.failed, errorCode: errorCode);
}

class CalorieScannedSourceRef {
  const CalorieScannedSourceRef({
    required this.barcode,
    required this.source,
    this.offProductId,
  });

  final String barcode;
  final CalorieProductSource source;
  final String? offProductId;
}

enum CalorieNutritionOcrStatus { succeeded, canceled, failed }

class CalorieNutritionOcrResult {
  const CalorieNutritionOcrResult._({
    required this.status,
    this.profile,
    this.draft,
    this.errorCode,
  });

  final CalorieNutritionOcrStatus status;
  final CalorieProductProfile? profile;
  final CalorieNutritionOcrDraft? draft;
  final String? errorCode;

  const CalorieNutritionOcrResult.succeeded({
    CalorieProductProfile? profile,
    CalorieNutritionOcrDraft? draft,
  }) : this._(
         status: CalorieNutritionOcrStatus.succeeded,
         profile: profile,
         draft: draft,
       );

  const CalorieNutritionOcrResult.canceled()
    : this._(status: CalorieNutritionOcrStatus.canceled);

  const CalorieNutritionOcrResult.failed({required String errorCode})
    : this._(status: CalorieNutritionOcrStatus.failed, errorCode: errorCode);
}
