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
                pendingSpeech: 'und dann noch ' * 10,
                onBack: () {},
                onSentence: (_) {},
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
}

Future<CookingGuide> _guide(WidgetTester tester) async {
  final recipe = preparedMealTestData(id: 'stew').copyWith(
    recipeIngredients: const ['500 g Hackfleisch', '200 g Karotten', 'Salz'],
    recipeInstructions: const [
      'Das Hackfleisch in einer großen Pfanne kräftig anbraten und salzen.',
    ],
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
