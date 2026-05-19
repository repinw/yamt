import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_prefill.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('tryParse accepts comma and dot decimals', () {
    final draft = CalorieEntryEditorDraft();
    addTearDown(draft.dispose);

    draft
      ..nameController.text = 'Greek Yogurt'
      ..brandController.text = 'Farm'
      ..amountController.text = '150,5'
      ..per100KcalController.text = '95.2'
      ..per100ProteinController.text = '9,8'
      ..per100CarbsController.text = '4.1'
      ..per100FatController.text = '0,5'
      ..mealType = MealType.breakfast
      ..consumedUnit = ConsumedUnit.milliliters
      ..loggedAt = DateTime(2026, 4, 19, 8, 30);

    final parsed = draft.tryParse();

    expect(parsed, isNotNull);
    expect(parsed!.name, 'Greek Yogurt');
    expect(parsed.brand, 'Farm');
    expect(parsed.amount, 150.5);
    expect(parsed.per100Kcal, 95.2);
    expect(parsed.per100Protein, 9.8);
    expect(parsed.per100Carbs, 4.1);
    expect(parsed.per100Fat, 0.5);
    expect(parsed.mealType, MealType.breakfast);
    expect(parsed.consumedUnit, ConsumedUnit.milliliters);
    expect(parsed.loggedAt, DateTime(2026, 4, 19, 8, 30));
  });

  test('tryParse returns null when required values are missing', () {
    final draft = CalorieEntryEditorDraft();
    addTearDown(draft.dispose);

    draft.nameController.text = '  ';
    draft.amountController.text = '100';
    draft.per100KcalController.text = '10';
    draft.per100ProteinController.text = '1';
    draft.per100CarbsController.text = '2';
    draft.per100FatController.text = '3';

    expect(draft.tryParse(), isNull);

    draft.nameController.text = 'Milk';
    draft.per100FatController.clear();

    expect(draft.tryParse(), isNull);
  });

  test('tryParse returns null for invalid amount text', () {
    final draft = CalorieEntryEditorDraft();
    addTearDown(draft.dispose);

    draft
      ..nameController.text = 'Milk'
      ..amountController.text = 'abc'
      ..per100KcalController.text = '10'
      ..per100ProteinController.text = '1'
      ..per100CarbsController.text = '2'
      ..per100FatController.text = '3';

    expect(draft.tryParse(), isNull);
  });

  test('initializeFromEntry populates draft and ignores same entry twice', () {
    final draft = CalorieEntryEditorDraft();
    addTearDown(draft.dispose);
    final entry = CalorieEntry.create(
      id: 'entry-1',
      userId: 'user-1',
      name: 'Skyr',
      brand: 'Arla',
      mealType: MealType.snack,
      consumedAmount: 200,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 100,
      per100Protein: 10,
      per100Carbs: 5,
      per100Fat: 1,
      loggedAt: DateTime(2026, 4, 18, 12),
      createdAt: DateTime(2026, 4, 18, 12),
      updatedAt: DateTime(2026, 4, 18, 12),
    );

    expect(draft.initializeFromEntry(entry), isTrue);
    expect(draft.nameController.text, 'Skyr');
    expect(draft.brandController.text, 'Arla');
    expect(draft.amountController.text, '200');
    expect(draft.per100KcalController.text, '100');
    expect(draft.mealType, MealType.snack);
    expect(draft.loggedAt, DateTime(2026, 4, 18, 12));

    draft.nameController.text = 'Changed';
    expect(draft.initializeFromEntry(entry), isFalse);
    expect(draft.nameController.text, 'Changed');
  });

  test(
    'initializeForCreate populates draft and ignores same prefill twice',
    () {
      final draft = CalorieEntryEditorDraft();
      addTearDown(draft.dispose);
      final prefill = CalorieEntryCreatePrefill(
        initializationKey: 'prefill-1',
        name: 'Banana',
        brand: 'Fruit Co',
        consumedAmount: 175.5,
        per100Kcal: 89,
        per100Protein: 1.1,
        per100Carbs: 22.8,
        per100Fat: 0.3,
        mealType: MealType.lunch,
        consumedUnit: ConsumedUnit.grams,
        loggedAt: DateTime(2026, 4, 19, 13),
      );

      expect(draft.initializeForCreate(prefill), isTrue);
      expect(draft.nameController.text, 'Banana');
      expect(draft.brandController.text, 'Fruit Co');
      expect(draft.amountController.text, '175.50');
      expect(draft.per100ProteinController.text, '1.10');
      expect(draft.mealType, MealType.lunch);
      expect(draft.loggedAt, DateTime(2026, 4, 19, 13));

      draft.nameController.text = 'Changed';
      expect(draft.initializeForCreate(prefill), isFalse);
      expect(draft.nameController.text, 'Changed');
    },
  );

  test('validators reject invalid and negative numbers', () {
    final draft = CalorieEntryEditorDraft();
    addTearDown(draft.dispose);

    expect(
      draft.positiveNumberValidator(null, l10n),
      l10n.caloriesPositiveNumberValidation,
    );
    expect(
      draft.positiveNumberValidator('0', l10n),
      l10n.caloriesPositiveNumberValidation,
    );
    expect(draft.positiveNumberValidator('0,5', l10n), isNull);

    expect(
      draft.nonNegativeNumberValidator('-1', l10n),
      l10n.caloriesNonNegativeNumberValidation,
    );
    expect(draft.nonNegativeNumberValidator('0', l10n), isNull);
    expect(draft.nonNegativeNumberValidator('1.5', l10n), isNull);
  });
}
