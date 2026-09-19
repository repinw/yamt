import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_overview_card.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('shows the first brand only', (tester) async {
    final entry = _regularEntry(brand: 'Aldi, Allfein Feinkost');

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));

    expect(find.text('Aldi'), findsOneWidget);
  });

  testWidgets('amount is tappable only with a callback', (tester) async {
    var pickCount = 0;
    final entry = _regularEntry();

    await tester.pumpWidget(
      _wrapOverview(
        entry: entry,
        width: 360,
        onPickAmount: () => pickCount += 1,
      ),
    );
    await tester.tap(find.byKey(CalorieEntryDetailKeys.amountValue));
    expect(pickCount, 1);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('shows only the day in the day control', (tester) async {
    final entry = _regularEntry();

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));

    expect(
      find.descendant(
        of: find.byKey(CalorieEntryDetailKeys.loggedDayButton),
        matching: find.textContaining('8:00'),
      ),
      findsNothing,
    );
  });

  testWidgets('renders a hero image when the entry has an image', (
    tester,
  ) async {
    final entry = _regularEntry(imageUrl: 'https://example.com/skyr.png');

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));

    expect(find.byType(Hero), findsOneWidget);
  });

  testWidgets('renders no hero without an image', (tester) async {
    await tester.pumpWidget(_wrapOverview(entry: _regularEntry(), width: 360));

    expect(find.byType(Hero), findsNothing);
  });

  testWidgets('renders local image bytes from provider', (tester) async {
    final imageRef = localImageAssetRef('asset-1');
    final entry = _regularEntry(imageAssetId: 'asset-1');

    await tester.pumpWidget(
      _wrapOverview(
        entry: entry,
        width: 360,
        overrides: [
          localImageBytesProvider(imageRef)
              .overrideWith((ref) async => _transparentPngBytes),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });

  testWidgets('falls back when local image provider has no bytes', (
    tester,
  ) async {
    final imageRef = localImageAssetRef('asset-1');
    final entry = _regularEntry(imageAssetId: 'asset-1');

    await tester.pumpWidget(
      _wrapOverview(
        entry: entry,
        width: 360,
        overrides: [
          localImageBytesProvider(imageRef).overrideWith((ref) async => null),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('shows brand eyebrow before bundle eyebrow', (tester) async {
    final entry = _bundleEntry(brand: 'Kitchen Club');

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));

    expect(find.byKey(CalorieEntryDetailKeys.brandValue), findsOneWidget);
    expect(find.text('Kitchen Club'), findsOneWidget);
    expect(find.text('Prepared meals'), findsNothing);
  });

  testWidgets('shows bundle eyebrow when brand is absent', (tester) async {
    final entry = _bundleEntry();

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));

    expect(find.byKey(CalorieEntryDetailKeys.brandValue), findsNothing);
    expect(find.text('Prepared meals'), findsOneWidget);
  });

  testWidgets('omits eyebrow for regular entries without brand', (
    tester,
  ) async {
    final entry = _regularEntry();

    await tester.pumpWidget(_wrapOverview(entry: entry, width: 360));

    expect(find.byKey(CalorieEntryDetailKeys.brandValue), findsNothing);
    expect(find.text('Prepared meals'), findsNothing);
  });
}

Widget _wrapOverview({
  required CalorieEntry entry,
  required double width,
  List<Override> overrides = const <Override>[],
  VoidCallback? onPickAmount,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: CalorieEntryOverviewCard(
              entry: entry,
              isSaving: false,
              onPickLoggedAt: () {},
              onMealTypeChanged: (_) {},
              onPickAmount: onPickAmount,
            ),
          ),
        ),
      ),
    ),
  );
}

CalorieEntry _regularEntry({
  String? imageAssetId,
  String? imageUrl,
  String? brand,
}) {
  final loggedAt = DateTime(2026, 2, 25, 8);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    brand: brand,
    imageUrl: imageUrl,
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    imageAssetId: imageAssetId,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntry _bundleEntry({String? brand}) {
  final loggedAt = DateTime(2026, 2, 25, 12);
  return CalorieEntry.bundle(
    id: 'bundle-1',
    userId: 'user-1',
    name: 'Chili',
    brand: brand,
    mealType: MealType.lunch,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        totalKcal: 120,
        totalProtein: 8,
        totalCarbs: 18,
        totalFat: 1,
      ),
    ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

final _transparentPngBytes = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
