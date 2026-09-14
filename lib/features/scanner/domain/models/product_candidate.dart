import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_candidate.freezed.dart';

/// Die Herkunft bzw. Sicherheit eines Produktvorschlags.
enum CandidateSource {
  /// Wurde aus einem vorherigen, vom Nutzer bestätigten
  /// Alias gelernt (100% Match).
  aliasExact,

  /// Wurde aus früheren Einkäufen / Inventar abgeleitet.
  history,

  /// Wurde per Text-Ähnlichkeit (Fuzzy-Search) im Katalog gefunden.
  catalogFuzzy,

  /// Wurde manuell per Barcode-Scan zugeordnet.
  barcode,

  /// Wurde über die manuelle Freitextsuche vom Nutzer ausgewählt.
  manualSearch,
}

/// Repräsentiert ein konkretes Produkt aus dem Katalog, das einer Belegzeile
/// zugeordnet werden kann.
@freezed
abstract class ProductCandidate with _$ProductCandidate {
  /// Erstellt eine Instanz von [ProductCandidate].
  const factory ProductCandidate({
    /// Eindeutige ID im Katalog (z. B. GlobalFoodItem-ID oder Barcode).
    required String id,

    /// Vollständiger Artikelname (z. B. "Ja! Frische Vollmilch 3,8%").
    required String name,

    /// Marke (z. B. "Ja!", "Milbona", "Bauer").
    String? brand,

    /// Kategorie (z. B. "Milch & Molkereiprodukte").
    String? category,

    /// EAN / Barcode (falls bekannt).
    String? barcode,

    /// Bild-URL des Produkts.
    String? imageUrl,

    /// Packungsgröße als Text (z. B. "1 l", "500 g", "4x125g").
    String? packageSize,

    /// Konfidenzwert zwischen 0.0 und 1.0.
    @Default(1.0) double confidence,

    /// Woher stammt dieser Vorschlag?
    @Default(CandidateSource.catalogFuzzy) CandidateSource source,

    /// Whether this candidate must be added to the global food catalog before
    /// inventory items and receipt aliases may reference it.
    @Default(false) bool requiresPersistence,

    /// Nährwerte pro 100g/ml.
    Map<String, num>? nutritionPer100g,
  }) = _ProductCandidate;

  const ProductCandidate._();

  /// Energy in kcal per 100g/ml if available.
  double? get kcal =>
      (nutritionPer100g?['kcal'] ?? nutritionPer100g?['energy_kcal'])
          ?.toDouble();

  /// Protein in grams per 100g/ml if available.
  double? get protein => nutritionPer100g?['protein']?.toDouble();

  /// Carbohydrates in grams per 100g/ml if available.
  double? get carbs => nutritionPer100g?['carbs']?.toDouble();

  /// Fat in grams per 100g/ml if available.
  double? get fat => nutritionPer100g?['fat']?.toDouble();

  /// Whether any macro nutrition value is present.
  bool get hasNutrition =>
      kcal != null || protein != null || carbs != null || fat != null;

  /// Compact formatted macro overview string
  /// (e.g. '64 kcal · F: 3.5g · KH: 4.8g · P: 3.4g').
  String? get formattedMacros {
    if (!hasNutrition) return null;
    final parts = <String>[];
    if (kcal != null) parts.add('${kcal!.round()} kcal');
    if (fat != null) parts.add('F: ${fat!.toStringAsFixed(1)}g');
    if (carbs != null) parts.add('KH: ${carbs!.toStringAsFixed(1)}g');
    if (protein != null) parts.add('P: ${protein!.toStringAsFixed(1)}g');
    return parts.join(' · ');
  }
}
