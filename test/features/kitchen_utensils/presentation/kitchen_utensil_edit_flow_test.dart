import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/kitchen_utensil_edit_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_kitchen_utensil_repository.dart';
import '../../../support/fake_prepared_meal_image_picker.dart';

const _addKey = ValueKey<String>('add-utensil');

/// A repository whose saves fail while [failSaves] is set.
class _Repository extends FakeKitchenUtensilRepository {
  bool failSaves = false;

  @override
  Future<bool> save(KitchenUtensil utensil) async =>
      !failSaves && await super.save(utensil);
}

class _Harness {
  new({this.title});

  final repository = _Repository();

  /// The title the add button asks the sheet for.
  final String? title;

  /// What the last tap on the button got.
  String? result;
  bool finished = false;

  Widget get app => UncontrolledProviderScope(
    container: ProviderContainer.test(
      overrides: [
        householdDataOwnerUserIdProvider.overrideWith((ref) => 'owner-1'),
        kitchenUtensilRepositoryProvider.overrideWithValue(repository),
        preparedMealImagePickerProvider.overrideWithValue(
          FakePreparedMealImagePicker(),
        ),
      ],
    ),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => FilledButton(
            key: _addKey,
            onPressed: () async {
              result = await KitchenUtensilEditFlow.add(
                context,
                ref,
                title: title,
              );
              finished = true;
            },
            child: const Text('Open the sheet'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _fillAndSave(WidgetTester tester) async {
  final l10n = AppLocalizations.of(tester.element(find.byKey(_addKey)))!;
  await tester.enterText(
    find.widgetWithText(TextField, l10n.kitchenUtensilNameLabel),
    'Wok',
  );
  await tester.enterText(
    find.widgetWithText(TextField, l10n.kitchenUtensilWeightLabel),
    '800',
  );
  await tester.tap(
    find.widgetWithText(FilledButton, l10n.kitchenUtensilAddShort),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('returns the id of the utensil it saved', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    await tester.tap(find.byKey(_addKey));
    await tester.pumpAndSettle();

    await _fillAndSave(tester);

    final stored = h.repository.utensils.single;
    expect(stored.name, 'Wok');
    expect(h.finished, isTrue);
    expect(h.result, stored.id);
  });

  testWidgets('titles the sheet "Add utensil" without a title of the caller', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    await tester.tap(find.byKey(_addKey));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byKey(_addKey)))!;

    expect(find.text(l10n.kitchenUtensilAddTitle), findsOneWidget);
    expect(find.text(l10n.kitchenUtensilWeightHelper), findsOneWidget);
  });

  testWidgets('titles the sheet with the title of the caller', (tester) async {
    final h = _Harness(title: 'Add a pot or pan');
    await tester.pumpWidget(h.app);
    await tester.tap(find.byKey(_addKey));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byKey(_addKey)))!;

    expect(find.text('Add a pot or pan'), findsOneWidget);
    expect(find.text(l10n.kitchenUtensilAddTitle), findsNothing);
  });

  testWidgets('says it saved, with an undo that removes the utensil', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    await tester.tap(find.byKey(_addKey));
    await tester.pumpAndSettle();
    await _fillAndSave(tester);
    final l10n = AppLocalizations.of(tester.element(find.byKey(_addKey)))!;

    expect(find.text(l10n.kitchenUtensilSavedMessage), findsOneWidget);
    await tester.tap(find.text(l10n.commonUndoAction));
    await tester.pumpAndSettle();

    expect(h.repository.utensils, isEmpty);
  });

  testWidgets('returns null when the cook closes the sheet', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    await tester.tap(find.byKey(_addKey));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(h.finished, isTrue);
    expect(h.result, isNull);
    expect(h.repository.utensils, isEmpty);
  });

  testWidgets('returns null and says so when saving fails', (tester) async {
    final h = _Harness()..repository.failSaves = true;
    await tester.pumpWidget(h.app);
    await tester.tap(find.byKey(_addKey));
    await tester.pumpAndSettle();

    await _fillAndSave(tester);
    final l10n = AppLocalizations.of(tester.element(find.byKey(_addKey)))!;

    expect(h.finished, isTrue);
    expect(h.result, isNull);
    expect(h.repository.utensils, isEmpty);
    expect(find.text(l10n.kitchenUtensilSavedMessage), findsNothing);
    expect(find.text(l10n.kitchenUtensilSaveFailed), findsOneWidget);
  });
}
