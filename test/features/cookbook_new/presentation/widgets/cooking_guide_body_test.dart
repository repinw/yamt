import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_guide_body.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_guide_sentence_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_guide_step_sheet.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

void main() {
  testWidgets('a sentence in large text on a small phone scrolls down to '
      'the voice zone', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final guide = await _guide(tester);

    final pending = ValueNotifier<String?>('und dann noch ' * 10);
    addTearDown(pending.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Scaffold(
              body: CookingGuideBody(
                guide: guide,
                sentence: 0,
                isCooking: false,
                isListening: true,
                pendingSpeech: pending,
                onBack: () {},
                onSentence: (_) {},
                onJump: (_) {},
                onDone: () {},
                onVoice: () {},
                onType: () {},
                onUndo: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(CookingGuideBody.typeKey),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows one bar segment per step and jumps to the first '
      'sentence of a picked step', (tester) async {
    final guide = await _guide(
      tester,
      steps: const [
        'Anbraten.',
        'Karotten schneiden. Dazugeben.',
        '',
        'Köcheln lassen.',
      ],
    );
    final picked = <int>[];
    final pending = ValueNotifier<String?>(null);
    addTearDown(pending.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CookingGuideBody(
            guide: guide,
            sentence: 1,
            isCooking: false,
            isListening: false,
            pendingSpeech: pending,
            onBack: () {},
            onSentence: (_) {},
            onJump: picked.add,
            onDone: () {},
            onVoice: () {},
            onType: () {},
            onUndo: () {},
          ),
        ),
      ),
    );

    // The empty third step has neither a segment nor a row.
    final bars = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect([for (final bar in bars) bar.value], [1, 0.5, 0]);

    await tester.tap(find.byKey(CookingGuideSentenceSection.jumpKey));
    await tester.pumpAndSettle();
    expect(find.byKey(CookingGuideStepSheet.stepKey(3)), findsNothing);
    await tester.tap(find.byKey(CookingGuideStepSheet.stepKey(4)));
    await tester.pumpAndSettle();
    expect(picked, [3]);
    expect(find.byType(CookingGuideStepSheet), findsNothing);
  });
}

Future<CookingGuide> _guide(
  WidgetTester tester, {
  List<String> steps = const [
    'Das Hackfleisch in einer großen Pfanne kräftig anbraten und salzen.',
  ],
}) async {
  final recipe = preparedMealTestData(id: 'stew').copyWith(
    recipeIngredients: const ['500 g Hackfleisch', '200 g Karotten', 'Salz'],
    recipeInstructions: steps,
  );
  final container = ProviderContainer(
    overrides: [
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value([recipe])),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value(const <InventoryItem>[]),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(recipeControllerProvider('stew'), (_, _) {});
  final provider = cookingGuideProvider('stew', 'de');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  await tester.runAsync(() async {
    while (container.read(provider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
  });
  return container.read(provider).requireValue!;
}
