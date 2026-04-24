import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/fake_prepared_meal_image_picker.dart';
import '../../../../../support/fake_local_image_store.dart';
import '../../../../../support/prepared_meal_test_data.dart';

class _EditSheetHarness extends StatefulWidget {
  const _EditSheetHarness({required this.meal});

  final PreparedMeal meal;

  @override
  State<_EditSheetHarness> createState() => _EditSheetHarnessState();
}

class _EditSheetHarnessState extends State<_EditSheetHarness> {
  String? _resultLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealEditSheet(
                context: context,
                meal: widget.meal,
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel =
                    'edited:${result.name}:${result.imageChanged}:'
                    '${result.imageBytes != null}';
              });
            },
            child: const Text('Open'),
          ),
          if (_resultLabel != null) Text(_resultLabel!),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('returns updated name on happy path submit', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealImagePickerProvider.overrideWithValue(
            FakePreparedMealImagePicker(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EditSheetHarness(meal: _meal()),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Updated bowl',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('edited:Updated bowl:false:false'), findsOneWidget);
  });

  testWidgets('can remove image and returns changed state', (tester) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-meal-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localImageStoreProvider.overrideWithValue(localImageStore),
          preparedMealImagePickerProvider.overrideWithValue(
            FakePreparedMealImagePicker(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EditSheetHarness(meal: _meal()),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove image'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('edited:Rice bowl:true:false'), findsOneWidget);
  });

  testWidgets('can pick replacement image and returns changed bytes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealImagePickerProvider.overrideWithValue(
            FakePreparedMealImagePicker(
              fileBytes: tinyPreparedMealPngBytes(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EditSheetHarness(meal: _meal()),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add image'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('edited:Rice bowl:true:true'), findsOneWidget);
  });
}

PreparedMeal _meal() {
  return preparedMealTestData(
    imageAssetId: 'asset-meal-1',
    totalPortions: 2,
    remainingPortions: 2,
  );
}
