import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_remember_portion.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_sheet_hero_image.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

EatRulerMark _mark(String label, double value, List<String> taps) {
  return EatRulerMark(
    label: label,
    value: value,
    isSelected: false,
    onPressed: () => taps.add(label),
  );
}

void main() {
  test('portion amounts use quarter glyphs', () {
    String plain(num value) => '$value';

    expect(formatQuickChipAmount(0.5, plain), '½');
    expect(formatQuickChipAmount(1.25, plain), '1¼');
    expect(formatQuickChipAmount(0.75, plain), '¾');
    expect(formatQuickChipAmount(2, plain), '2');
    expect(formatQuickChipAmount(0.3, plain), '0.3');
  });

  testWidgets('header shows the image, the brand in capitals and the name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: EatPageHeader(
          title: 'Rice bowl',
          brand: 'Acme',
          caption: '2 port. in stock',
          imageBytes: _pngBytes(),
          imageKey: const Key('hero_image'),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('hero_image')),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<MemoryImage>());
    expect(find.text('ACME'), findsOneWidget);
    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.text('2 port. in stock'), findsOneWidget);
  });

  testWidgets('hero image falls back when image url is invalid', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: EatSheetHeroImage(
          imageUrl: 'not a url',
          fallback: Text('fallback'),
        ),
      ),
    );

    expect(find.text('fallback'), findsOneWidget);
  });

  testWidgets('ruler lists every mark from the smallest up', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      _TestApp(
        child: EatRuler(
          value: 0,
          max: 1000,
          step: 25,
          marks: [
            _mark('All', 1000, taps),
            _mark('Large slice 40', 40, taps),
            _mark('Slice 30', 30, taps),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    final lefts = [
      for (final label in ['Slice 30', 'Large slice 40', 'All'])
        tester.getTopLeft(find.text(label)),
    ];
    for (final (index, left) in lefts.indexed.skip(1)) {
      final previous = lefts[index - 1];
      expect(
        left.dy > previous.dy || left.dx > previous.dx,
        isTrue,
        reason: 'marks keep their order without overlapping',
      );
    }

    await tester.tap(find.text('All'));
    expect(taps, ['All']);
  });

  testWidgets('ruler snaps to its step and to the maximum', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(
      _TestApp(
        child: EatRuler(
          value: 0,
          max: 183,
          step: 5,
          marks: const [],
          onChanged: values.add,
        ),
      ),
    );

    final slider = find.byKey(EatRuler.sliderKey);
    final rect = tester.getRect(slider);
    await tester.tapAt(rect.centerLeft + Offset(rect.width * 0.5, 0));
    await tester.tapAt(rect.centerRight - const Offset(1, 0));

    expect(values.first % 5, 0);
    expect(values.last, 183);
  });

  testWidgets('remember portion asks only for a name', (tester) async {
    final saved = <String>[];
    await tester.pumpWidget(
      _TestApp(
        child: EatRememberPortion(amountLabel: '60 g', onSave: saved.add),
      ),
    );

    await tester.tap(find.byKey(EatRememberPortion.linkKey));
    await tester.pumpAndSettle();
    expect(find.text('Name for 60 g'), findsOneWidget);

    await tester.enterText(
      find.byKey(EatRememberPortion.nameFieldKey),
      'Slice',
    );
    await tester.tap(find.byKey(EatRememberPortion.saveKey));
    await tester.pumpAndSettle();

    expect(saved, ['Slice']);
    expect(find.byKey(EatRememberPortion.nameFieldKey), findsNothing);
    expect(find.byKey(EatRememberPortion.linkKey), findsOneWidget);
  });

  testWidgets('page scaffold shows the calories and closes', (tester) async {
    var confirmTapCount = 0;
    var secondaryTapCount = 0;
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EatPageScaffold(
                  whenControl: const Text('TODAY · SNACK'),
                  kcal: 216.6,
                  confirmButtonKey: const Key('confirm'),
                  onConfirm: () => confirmTapCount += 1,
                  cancelButtonKey: const Key('close'),
                  secondaryLabel: '+ More',
                  secondaryButtonKey: const Key('more'),
                  onSecondary: () => secondaryTapCount += 1,
                  children: const [Text('Body')],
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('TODAY · SNACK'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('217 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm')));
    await tester.tap(find.byKey(const Key('more')));
    expect(confirmTapCount, 1);
    expect(secondaryTapCount, 1);

    await tester.tap(find.byKey(const Key('close')));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('page scaffold keeps earlier snack bars off the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Logged')));
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EatPageScaffold(
                    whenControl: const SizedBox(),
                    kcal: null,
                    confirmButtonKey: const Key('confirm'),
                    onConfirm: () {},
                    cancelButtonKey: const Key('close'),
                    children: const [Text('Body')],
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Logged'), findsNothing);
  });

  testWidgets('food label colors follow the brightness', (tester) async {
    late FoodLabelColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            colors = FoodLabelColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(colors, same(FoodLabelColors.dark));
  });
}

Uint8List _pngBytes() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAFgwJ/lR3pWQAAAABJRU5ErkJggg==',
  );
}

class _TestApp extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }
}
