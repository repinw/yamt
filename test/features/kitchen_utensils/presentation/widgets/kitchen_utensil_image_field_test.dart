import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_image_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required ValueChanged<KitchenUtensilImageSource> onPickImage,
  required VoidCallback onClearImage,
  bool supportsCamera = true,
  bool isPickingImage = false,
  String? imageUrl,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: KitchenUtensilImageField(
        label: 'Pot',
        imageBytes: null,
        imageUrl: imageUrl,
        supportsCamera: supportsCamera,
        isPickingImage: isPickingImage,
        onPickImage: onPickImage,
        onClearImage: onClearImage,
      ),
    ),
  );
}

void main() {
  testWidgets('shows image actions and emits selected source', (tester) async {
    final pickedSources = <KitchenUtensilImageSource>[];
    var clearCount = 0;

    await tester.pumpWidget(
      _buildHarness(
        imageUrl: 'https://example.test/pot.jpg',
        onPickImage: pickedSources.add,
        onClearImage: () {
          clearCount += 1;
        },
      ),
    );

    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsOneWidget);

    await tester.tap(find.text('Take photo'));
    await tester.pump();
    await tester.tap(find.text('Change photo'));
    await tester.pump();
    await tester.tap(find.text('Remove photo'));
    await tester.pump();

    expect(
      pickedSources,
      [KitchenUtensilImageSource.camera, KitchenUtensilImageSource.file],
    );
    expect(clearCount, 1);
  });

  testWidgets('hides camera and disables file action while picking', (
    tester,
  ) async {
    final pickedSources = <KitchenUtensilImageSource>[];

    await tester.pumpWidget(
      _buildHarness(
        supportsCamera: false,
        isPickingImage: true,
        onPickImage: pickedSources.add,
        onClearImage: () {},
      ),
    );

    expect(find.text('Take photo'), findsNothing);
    expect(find.text('Add photo'), findsOneWidget);

    await tester.tap(find.text('Add photo'));
    await tester.pump();

    expect(pickedSources, isEmpty);
  });
}
