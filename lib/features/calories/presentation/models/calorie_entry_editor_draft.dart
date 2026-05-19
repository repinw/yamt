import 'package:flutter/material.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_prefill.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Parsed, validated values from calorie entry editor form.
typedef CalorieEntryEditorParsedDraft = ({
  String name,
  String? brand,
  double amount,
  double per100Kcal,
  double per100Protein,
  double per100Carbs,
  double per100Fat,
  MealType mealType,
  ConsumedUnit consumedUnit,
  DateTime loggedAt,
});

/// Owns calorie entry editor form controllers and parsed draft values.
class CalorieEntryEditorDraft {
  /// Creates draft with default amount.
  CalorieEntryEditorDraft();

  /// Form key for editor.
  final formKey = GlobalKey<FormState>();

  /// Name controller.
  final nameController = TextEditingController();

  /// Brand controller.
  final brandController = TextEditingController();

  /// Amount controller.
  final amountController = TextEditingController(text: '100');

  /// Calories controller.
  final per100KcalController = TextEditingController();

  /// Protein controller.
  final per100ProteinController = TextEditingController();

  /// Carbs controller.
  final per100CarbsController = TextEditingController();

  /// Fat controller.
  final per100FatController = TextEditingController();

  /// Selected meal type.
  MealType mealType = MealType.defaultForDateTime(DateTime.now());

  /// Selected consumed unit.
  ConsumedUnit consumedUnit = ConsumedUnit.grams;

  /// Logged-at value.
  DateTime loggedAt = DateTime.now();

  String? _initializedEntryId;

  /// Releases text editing resources.
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    amountController.dispose();
    per100KcalController.dispose();
    per100ProteinController.dispose();
    per100CarbsController.dispose();
    per100FatController.dispose();
  }

  /// Loads draft fields from existing entry.
  bool initializeFromEntry(CalorieEntry? entry) {
    final nextEntryId = entry?.id ?? '__new_entry__';
    if (_initializedEntryId == nextEntryId) {
      return false;
    }

    nameController.text = entry?.name ?? '';
    brandController.text = entry?.brand ?? '';
    amountController.text = _formatDouble(entry?.consumedAmount ?? 100);
    per100KcalController.text = _formatDouble(entry?.per100Kcal ?? 0);
    per100ProteinController.text = _formatDouble(entry?.per100Protein ?? 0);
    per100CarbsController.text = _formatDouble(entry?.per100Carbs ?? 0);
    per100FatController.text = _formatDouble(entry?.per100Fat ?? 0);
    mealType = entry?.mealType ?? MealType.defaultForDateTime(DateTime.now());
    consumedUnit = entry?.consumedUnit ?? ConsumedUnit.grams;
    loggedAt = entry?.loggedAt ?? DateTime.now();
    _initializedEntryId = nextEntryId;
    return true;
  }

  /// Loads draft fields from create prefill.
  bool initializeForCreate(CalorieEntryCreatePrefill createPrefill) {
    if (_initializedEntryId == createPrefill.initializationKey) {
      return false;
    }

    nameController.text = createPrefill.name;
    brandController.text = createPrefill.brand ?? '';
    amountController.text = _formatDouble(createPrefill.consumedAmount);
    per100KcalController.text = _formatDouble(createPrefill.per100Kcal);
    per100ProteinController.text = _formatDouble(createPrefill.per100Protein);
    per100CarbsController.text = _formatDouble(createPrefill.per100Carbs);
    per100FatController.text = _formatDouble(createPrefill.per100Fat);
    mealType = createPrefill.mealType;
    consumedUnit = createPrefill.consumedUnit;
    loggedAt = createPrefill.loggedAt;
    _initializedEntryId = createPrefill.initializationKey;
    return true;
  }

  /// Whether details draft changed compared with existing entry.
  bool hasPendingChangesForEntry(CalorieEntry entry) {
    return mealType != entry.mealType || loggedAt != entry.loggedAt;
  }

  /// Validates positive number input.
  String? positiveNumberValidator(String? value, AppLocalizations l10n) {
    final parsed = _parseDouble(value);
    if (parsed == null || parsed <= 0) {
      return l10n.caloriesPositiveNumberValidation;
    }
    return null;
  }

  /// Validates non-negative number input.
  String? nonNegativeNumberValidator(String? value, AppLocalizations l10n) {
    final parsed = _parseDouble(value);
    if (parsed == null || parsed < 0) {
      return l10n.caloriesNonNegativeNumberValidation;
    }
    return null;
  }

  /// Parses current form values into typed draft.
  CalorieEntryEditorParsedDraft? tryParse() {
    final amount = _parseDouble(amountController.text);
    final per100Kcal = _parseDouble(per100KcalController.text);
    final per100Protein = _parseDouble(per100ProteinController.text);
    final per100Carbs = _parseDouble(per100CarbsController.text);
    final per100Fat = _parseDouble(per100FatController.text);
    final trimmedName = nameController.text.trim();
    final trimmedBrand = brandController.text.trim();

    if (trimmedName.isEmpty ||
        amount == null ||
        per100Kcal == null ||
        per100Protein == null ||
        per100Carbs == null ||
        per100Fat == null) {
      return null;
    }

    return (
      name: trimmedName,
      brand: trimmedBrand.isEmpty ? null : trimmedBrand,
      amount: amount,
      per100Kcal: per100Kcal,
      per100Protein: per100Protein,
      per100Carbs: per100Carbs,
      per100Fat: per100Fat,
      mealType: mealType,
      consumedUnit: consumedUnit,
      loggedAt: loggedAt,
    );
  }

  double? _parseDouble(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatDouble(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
