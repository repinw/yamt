import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_header.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _long =
    'Ofengemuese mit Kartoffeln, Karotten, Zucchini, Paprika und '
    'Kraeuterquark aus dem Backofen fuer die ganze Familie am Sonntag '
    'mit extra viel Knoblauch und frischem Thymian';

// A valid 1x1 picture.
final Uint8List _photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

Future<TextEditingController> _pump(
  WidgetTester tester, {
  String name = '',
  double width = 400,
  double textScale = 1,
  int portions = 4,
  ValueChanged<int>? onPortions,
  Uint8List? photo,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = TextEditingController(text: name);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RecipeEditorHeader(
            nameController: controller,
            onNameChanged: (_) {},
            portions: portions,
            onPortionsChanged: onPortions ?? (_) {},
            photo: photo,
            original: null,
            onPhoto: () {},
          ),
        ),
      ),
    ),
  );
  return controller;
}

Rect _rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

void main() {
  testWidgets('the name field grows with a long name', (tester) async {
    await _pump(tester, name: 'Pasta');
    final oneLine = _rect(tester, RecipeEditorHeader.nameKey).height;

    await _pump(tester, name: _long);
    final grown = _rect(tester, RecipeEditorHeader.nameKey).height;

    expect(grown, greaterThan(oneLine * 1.5));
  });

  testWidgets('the name field stops at three lines', (tester) async {
    await _pump(tester, name: _long);
    final three = _rect(tester, RecipeEditorHeader.nameKey).height;

    await _pump(tester, name: '$_long $_long $_long');

    expect(_rect(tester, RecipeEditorHeader.nameKey).height, three);
  });

  testWidgets('shows the whole long name in the field', (tester) async {
    final controller = await _pump(tester, name: _long);

    expect(controller.text, _long);
    final field = tester.widget<TextField>(
      find.byKey(RecipeEditorHeader.nameKey),
    );
    expect(field.maxLines, 3);
    expect(field.minLines, 1);
  });

  testWidgets('the portions stand under the photo and the name', (
    tester,
  ) async {
    await _pump(tester, name: _long);

    final photo = _rect(tester, RecipeEditorHeader.photoKey);
    final name = _rect(tester, RecipeEditorHeader.nameKey);
    final portions = _rect(tester, RecipeEditorHeader.portionsKey);

    expect(portions.top, greaterThanOrEqualTo(photo.bottom));
    expect(portions.top, greaterThanOrEqualTo(name.bottom));
    expect(name.left, greaterThanOrEqualTo(photo.right));
  });

  testWidgets('the portion stepper still counts', (tester) async {
    var portions = 4;
    await _pump(tester, onPortions: (value) => portions = value);

    await tester.tap(find.byKey(RecipeEditorHeader.morePortionsKey));

    expect(portions, 5);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('a long name does not overflow at 320 px and text scale $scale '
        'with a photo', (tester) async {
      await _pump(
        tester,
        name: _long,
        width: 320,
        textScale: scale,
        photo: _photo,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(RecipeEditorHeader.portionsKey), findsOneWidget);
    });
  }

  testWidgets('a long name does not overflow at 320 px and text scale 1.3', (
    tester,
  ) async {
    await _pump(tester, name: _long, width: 320, textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(find.byKey(RecipeEditorHeader.portionsKey), findsOneWidget);
  });
}
