import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_flow.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_content.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User;

User _user() {
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  return user;
}

const _openKey = Key('open_editor');
const _otherPath = '/other';

/// What the editor popped, once it closed.
class _EditorResult {
  CalorieEntry? entry;
  bool returned = false;
  late GoRouter router;
}

/// Opens the editor from a root page, as the Vorrat eat flow does, and keeps
/// what it returns.
Future<_EditorResult> _openEditor(
  WidgetTester tester, {
  CalorieProductProfile? prefilledProfile,
  double? prefilledAmount,
  ConsumedUnit? prefilledUnit,
  MealType? preselectedMealType,
}) async {
  final result = _EditorResult();
  result.router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            key: _openKey,
            onPressed: () async {
              final entry = await showCalorieEntryEditor(
                context,
                prefilledProfile: prefilledProfile,
                prefilledAmount: prefilledAmount,
                prefilledUnit: prefilledUnit,
                preselectedMealType: preselectedMealType,
              );
              result
                ..entry = entry
                ..returned = true;
            },
            child: const Text('Root'),
          ),
        ),
      ),
      GoRoute(
        path: _otherPath,
        builder: (context, state) => const Scaffold(body: Text('Other')),
      ),
    ],
  );
  final user = _user();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        routerConfig: result.router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  return result;
}

Future<void> _fillGreekYogurt(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(CalorieEntryEditorKeys.nameField),
    'Greek Yogurt',
  );
  await tester.enterText(
    find.byKey(CalorieEntryEditorKeys.per100KcalField),
    '95',
  );
  await tester.enterText(
    find.byKey(CalorieEntryEditorKeys.per100ProteinField),
    '9.8',
  );
  await tester.enterText(
    find.byKey(CalorieEntryEditorKeys.per100CarbsField),
    '4.1',
  );
  await tester.enterText(
    find.byKey(CalorieEntryEditorKeys.per100FatField),
    '0.5',
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
  await tester.pumpAndSettle();
}

CalorieProductProfile _yogurt({
  String barcode = '4006381333931',
  String? imageUrl,
}) {
  return CalorieProductProfile(
    barcode: barcode,
    name: 'Greek Yogurt',
    brand: 'Test Brand',
    per100Kcal: 95,
    per100Protein: 9.8,
    per100Carbs: 4.1,
    per100Fat: 0.5,
    source: CalorieProductSource.offBarcode,
    offProductId: 'off-$barcode',
    imageUrl: imageUrl,
    createdAt: DateTime(2026, 2, 25, 8),
    updatedAt: DateTime(2026, 2, 25, 8),
  );
}

Widget _directEditor({
  required String barcode,
  required MealType mealType,
  required DateTime loggedAt,
}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CalorieEntryEditorContent(
      key: const ValueKey('editor-content'),
      user: _user(),
      prefilledProfile: _yogurt(barcode: barcode),
      preselectedMealType: mealType,
      preselectedLoggedAt: loggedAt,
    ),
  );
}

void main() {
  testWidgets('create editor refreshes draft when create context changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _directEditor(
        barcode: '4006381333931',
        mealType: MealType.lunch,
        loggedAt: DateTime(2026, 2, 25, 12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Greek Yogurt'), findsOneWidget);

    await tester.pumpWidget(
      _directEditor(
        barcode: '4012345678901',
        mealType: MealType.snack,
        loggedAt: DateTime(2026, 2, 26, 15),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Greek Yogurt'), findsOneWidget);
  });

  testWidgets('save returns the new entry to the caller', (tester) async {
    final result = await _openEditor(tester);

    await _fillGreekYogurt(tester);
    await _save(tester);

    expect(result.returned, isTrue);
    expect(result.entry?.name, 'Greek Yogurt');
    expect(result.entry?.userId, 'user-1');
    expect(result.entry?.per100Kcal, 95);
    expect(result.entry?.sourceInventoryItemId, isNull);
    expect(find.byKey(_openKey), findsOneWidget);
  });

  testWidgets('the prefill fills the amount and the profile', (tester) async {
    final result = await _openEditor(
      tester,
      prefilledProfile: _yogurt(
        imageUrl: 'https://images.example.com/yogurt.jpg',
      ),
      prefilledAmount: 150,
      prefilledUnit: ConsumedUnit.milliliters,
      preselectedMealType: MealType.breakfast,
    );

    await _save(tester);

    expect(result.entry?.name, 'Greek Yogurt');
    expect(result.entry?.consumedAmount, 150);
    expect(result.entry?.consumedUnit, ConsumedUnit.milliliters);
    expect(result.entry?.mealType, MealType.breakfast);
    expect(result.entry?.imageUrl, 'https://images.example.com/yogurt.jpg');
  });

  testWidgets('back returns nothing', (tester) async {
    final result = await _openEditor(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(result.returned, isTrue);
    expect(result.entry, isNull);
  });

  testWidgets('a jump to another page returns nothing', (tester) async {
    final result = await _openEditor(tester);

    result.router.go(_otherPath);
    await tester.pumpAndSettle();

    expect(find.text('Other'), findsOneWidget);
    expect(result.returned, isTrue);
    expect(result.entry, isNull);
  });

  testWidgets('validation blocks save for empty name', (tester) async {
    final result = await _openEditor(tester);

    await tester.enterText(find.byKey(CalorieEntryEditorKeys.nameField), '');
    await _save(tester);

    expect(find.text('This field is required.'), findsOneWidget);
    expect(result.returned, isFalse);
  });

  testWidgets('validation blocks save for negative consumed amount', (
    tester,
  ) async {
    final result = await _openEditor(tester);

    await _fillGreekYogurt(tester);
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.amountField),
      '-10',
    );
    await _save(tester);

    expect(
      find.text('Please enter a number greater than zero.'),
      findsOneWidget,
    );
    expect(result.returned, isFalse);
  });

  testWidgets('validation blocks save for invalid number characters', (
    tester,
  ) async {
    final result = await _openEditor(tester);

    await _fillGreekYogurt(tester);
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100ProteinField),
      'abc',
    );
    await _save(tester);

    expect(
      find.text('Please enter a number equal to or greater than zero.'),
      findsOneWidget,
    );
    expect(result.returned, isFalse);
  });
}
