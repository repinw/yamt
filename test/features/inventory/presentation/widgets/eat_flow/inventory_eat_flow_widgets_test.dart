import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_amount_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_hero_image.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_quick_chip_scroller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_sheet_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/'
    'inventory_eat_flow_when_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('amount card uses broom clear icon and wires callbacks', (
    tester,
  ) async {
    final controller = TextEditingController(text: '12');
    final focusNode = FocusNode();
    final changedValues = <String>[];
    var clearTapCount = 0;
    var submitTapCount = 0;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _TestApp(
        child: InventoryEatFlowAmountCard(
          controller: controller,
          focusNode: focusNode,
          errorText: 'Bad amount',
          allowFractionalInput: true,
          clearTooltip: 'Clear amount',
          fieldKey: const Key('amount_field'),
          clearButtonKey: const Key('amount_clear'),
          trailing: const Text('grams'),
          onChanged: changedValues.add,
          onClearAndFocus: () {
            clearTapCount += 1;
          },
          onSubmitted: () {
            submitTapCount += 1;
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.cleaning_services_outlined), findsOneWidget);
    expect(find.text('Bad amount'), findsOneWidget);
    expect(find.text('grams'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amount_field')), '34');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.byKey(const Key('amount_clear')));
    await tester.pump();

    expect(changedValues, <String>['34']);
    expect(submitTapCount, 1);
    expect(clearTapCount, 1);
  });

  testWidgets('amount card accepts a custom clear icon', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _TestApp(
        child: InventoryEatFlowAmountCard(
          controller: controller,
          focusNode: focusNode,
          errorText: null,
          allowFractionalInput: false,
          clearTooltip: 'Clear amount',
          fieldKey: const Key('amount_field'),
          clearButtonKey: const Key('amount_clear'),
          clearIcon: Icons.backspace_outlined,
          trailing: const Text('pieces'),
          onChanged: (_) {},
          onClearAndFocus: () {},
          onSubmitted: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    expect(find.byIcon(Icons.cleaning_services_outlined), findsNothing);
  });

  testWidgets('hero shows memory image and close button dismisses sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) {
                      return InventoryEatFlowHero(
                        title: 'Rice bowl',
                        eyebrow: 'Eat meal',
                        imageBytes: _pngBytes(),
                        imageKey: const Key('hero_image'),
                        cancelButtonKey: const Key('close_sheet'),
                        fallback: const Text('fallback'),
                      );
                    },
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('hero_image')),
        matching: find.byType(Image),
      ),
    );
    expect(image.image, isA<MemoryImage>());
    expect(find.text('RICE BOWL'), findsNothing);
    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.text('EAT MEAL'), findsOneWidget);

    await tester.tap(find.byKey(const Key('close_sheet')));
    await tester.pumpAndSettle();

    expect(find.text('Rice bowl'), findsNothing);
  });

  testWidgets('hero image falls back when image url is invalid', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: InventoryEatFlowHeroImage(
          imageUrl: 'not a url',
          fallback: Text('fallback'),
        ),
      ),
    );

    expect(find.text('fallback'), findsOneWidget);
  });

  testWidgets('quick chip scroller lays out chips and handles taps', (
    tester,
  ) async {
    final taps = <String>[];

    await tester.pumpWidget(
      _TestApp(
        child: InventoryEatFlowQuickChipScroller(
          children: [
            InventoryEatFlowQuickChip(
              label: 'All',
              isSelected: true,
              onPressed: () => taps.add('all'),
            ),
            InventoryEatFlowQuickChip(
              label: '1',
              isSelected: false,
              onPressed: () => taps.add('one'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('1'));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(taps, <String>['one']);
  });

  testWidgets('when section toggles date card and meal type callbacks', (
    tester,
  ) async {
    var dateTapCount = 0;
    MealType? selectedMealType;

    await tester.pumpWidget(
      _TestApp(
        child: InventoryEatFlowWhenSection(
          isToday: true,
          label: null,
          selectedMealType: MealType.breakfast,
          loggedAtButtonKey: const Key('logged_at_button'),
          loggedAtCompactKey: const Key('logged_at_compact'),
          loggedAtLabeledKey: const Key('logged_at_labeled'),
          onPickLoggedAt: () {
            dateTapCount += 1;
          },
          onMealTypeSelected: (value) {
            selectedMealType = value;
          },
        ),
      ),
    );

    expect(find.byKey(const Key('logged_at_compact')), findsOneWidget);
    expect(find.byKey(const Key('logged_at_labeled')), findsNothing);

    await tester.tap(find.byKey(const Key('logged_at_button')));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<MealType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner').last);
    await tester.pumpAndSettle();

    expect(dateTapCount, 1);
    expect(selectedMealType, MealType.dinner);

    await tester.pumpWidget(
      _TestApp(
        child: InventoryEatFlowWhenSection(
          isToday: false,
          label: 'Apr 30, 2026',
          selectedMealType: MealType.dinner,
          loggedAtButtonKey: const Key('logged_at_button'),
          loggedAtCompactKey: const Key('logged_at_compact'),
          loggedAtLabeledKey: const Key('logged_at_labeled'),
          onPickLoggedAt: () {},
          onMealTypeSelected: (_) {},
        ),
      ),
    );

    expect(find.byKey(const Key('logged_at_compact')), findsNothing);
    expect(find.byKey(const Key('logged_at_labeled')), findsOneWidget);
    expect(find.text('Apr 30, 2026'), findsOneWidget);
  });

  testWidgets('sheet scaffold renders content and confirm footer', (
    tester,
  ) async {
    var confirmTapCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: InventoryEatFlowSheetScaffold(
          viewInsetsBottom: 12,
          hero: const Text('Hero'),
          confirmActionText: 'Eat',
          confirmButtonKey: const Key('confirm'),
          onConfirm: () {
            confirmTapCount += 1;
          },
          children: const [Text('Body')],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pump();

    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Eat'), findsOneWidget);
    expect(confirmTapCount, 1);
  });
}

Uint8List _pngBytes() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAFgwJ/lR3pWQAAAABJRU5ErkJggg==',
  );
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
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }
}
