import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_image_picker_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/fake_prepared_meal_image_picker.dart';

void main() {
  testWidgets('renders add action when no image is selected', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: PreparedMealImagePickerField(
          label: 'Soup',
          imageBytes: null,
          supportsCamera: true,
          isPickingImage: false,
          onPickImage: (_) {},
          onClearImage: () {},
        ),
      ),
    );

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Add image'), findsOneWidget);
    expect(find.text('Change image'), findsNothing);
    expect(find.text('Remove image'), findsNothing);
  });

  testWidgets('renders change and remove actions when image is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: PreparedMealImagePickerField(
          label: 'Soup',
          imageBytes: tinyPreparedMealPngBytes(),
          supportsCamera: false,
          isPickingImage: false,
          onPickImage: (_) {},
          onClearImage: () {},
        ),
      ),
    );

    expect(find.text('Take photo'), findsNothing);
    expect(find.text('Add image'), findsNothing);
    expect(find.text('Change image'), findsOneWidget);
    expect(find.text('Remove image'), findsOneWidget);
  });

  testWidgets('emits source callbacks and clear callback', (tester) async {
    final pickedSources = <PreparedMealImageSource>[];
    var clearCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: PreparedMealImagePickerField(
          label: 'Soup',
          imageBytes: tinyPreparedMealPngBytes(),
          supportsCamera: true,
          isPickingImage: false,
          onPickImage: pickedSources.add,
          onClearImage: () {
            clearCount += 1;
          },
        ),
      ),
    );

    expect(find.text('Cover image'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Change image'), findsOneWidget);
    expect(find.text('Remove image'), findsOneWidget);

    await tester.tap(find.text('Take photo'));
    await tester.tap(find.text('Change image'));
    await tester.tap(find.text('Remove image'));

    expect(
      pickedSources,
      <PreparedMealImageSource>[
        PreparedMealImageSource.camera,
        PreparedMealImageSource.file,
      ],
    );
    expect(clearCount, 1);
  });

  testWidgets('hides unavailable actions and disables while picking', (
    tester,
  ) async {
    final pickedSources = <PreparedMealImageSource>[];

    await tester.pumpWidget(
      _TestApp(
        child: PreparedMealImagePickerField(
          label: 'Soup',
          imageBytes: null,
          supportsCamera: false,
          isPickingImage: true,
          onPickImage: pickedSources.add,
          onClearImage: () {},
        ),
      ),
    );

    expect(find.text('Take photo'), findsNothing);
    expect(find.text('Add image'), findsOneWidget);
    expect(find.text('Remove image'), findsNothing);

    await tester.tap(find.text('Add image'));

    expect(pickedSources, isEmpty);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
