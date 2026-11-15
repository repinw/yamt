import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_setup_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_sheet.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_ai_chef.dart';
import '../../../../helpers/fake_inventory_item_repository.dart';

const _openKey = ValueKey<String>('open-sheet');

Future<void> _pump(
  WidgetTester tester,
  FakeAiChef chef,
  void Function(AiChefRecipeIdea?) onResult,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiChefRepositoryProvider.overrideWithValue(chef.repository),
        aiChefImageGeneratorProvider.overrideWithValue(chef.imageGenerator),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 13)),
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository(const []),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              key: _openKey,
              onPressed: () async => onResult(await AiChefSheet.show(context)),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

Future<void> _generate(WidgetTester tester) async {
  await tester.tap(find.byKey(AiChefSetupView.generateKey));
  await tester.pump();
}

void main() {
  testWidgets('shows the setup first', (tester) async {
    await _pump(tester, FakeAiChef(), (_) {});

    expect(find.text('Worauf hast du Lust?'), findsOneWidget);
    expect(find.byKey(AiChefSetupView.generateKey), findsOneWidget);
  });

  testWidgets('shows the loading view while the idea comes', (tester) async {
    final chef = FakeAiChef();
    await _pump(tester, chef, (_) {});

    await _generate(tester);

    expect(find.text('Wir stellen ein Rezept zusammen …'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(AiChefSetupView.generateKey), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('pops with the idea as soon as its text is there', (
    tester,
  ) async {
    final chef = FakeAiChef();
    AiChefRecipeIdea? result;
    var closed = false;
    await _pump(tester, chef, (idea) {
      closed = true;
      result = idea;
    });

    await _generate(tester);
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result!.recipe.name, 'Tomatenpasta');
    expect(result!.imagePrompt, 'a plate of pasta');
    expect(chef.pictureCalls, 0);
    expect(find.byType(AiChefSheet), findsNothing);
  });

  testWidgets('a failed idea shows the message and retry', (tester) async {
    final chef = FakeAiChef()..templateFails = true;
    var closed = false;
    await _pump(tester, chef, (_) => closed = true);

    await _generate(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Wir konnten gerade kein Rezept zusammenstellen.'),
      findsOneWidget,
    );
    expect(find.byKey(AiChefSheet.retryKey), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('retry asks again and pops with the idea', (tester) async {
    final chef = FakeAiChef()..templateFails = true;
    AiChefRecipeIdea? result;
    await _pump(tester, chef, (idea) => result = idea);
    await _generate(tester);
    await tester.pumpAndSettle();

    chef.templateFails = false;
    await tester.tap(find.byKey(AiChefSheet.retryKey));
    await tester.pumpAndSettle();

    expect(chef.templateCalls, 2);
    expect(result!.recipe.name, 'Tomatenpasta');
  });

  testWidgets('an unusable answer shows the failure too', (tester) async {
    final chef = FakeAiChef(answer: '{"name": "x"}');
    await _pump(tester, chef, (_) {});

    await _generate(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(AiChefSheet.retryKey), findsOneWidget);
  });

  testWidgets('closing the sheet gives null', (tester) async {
    var closed = false;
    AiChefRecipeIdea? result;
    await _pump(tester, FakeAiChef(), (idea) {
      closed = true;
      result = idea;
    });

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });
}
