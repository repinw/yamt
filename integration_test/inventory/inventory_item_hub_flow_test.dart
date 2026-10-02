import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_missing_values_hint.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/auth_user_data_key_session.dart';

const _openKey = Key('open_item_hub');

/// Eggs in stock from OFF: "10 Stück" without grams per piece, no salt.
final InventoryItem _eggs = InventoryItem.create(
  id: 'item-eggs',
  name: 'Eier',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Aldi',
  quantity: 1,
  weight: '10 Stück',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 137,
    per100Fat: 9.3,
    per100SaturatedFat: 2.7,
    per100Carbs: 0.7,
    per100Sugar: 0.7,
    per100Protein: 12.6,
  ),
).withDerivedAmount();

Widget _buildHarness({required List<InventoryItemHubAction> actions}) {
  // Signed out: the hub's shopping list and serving reads stay empty.
  final container = ProviderContainer(
    overrides: [
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => InventoryItemHubPage(
                    item: _eggs,
                    onAction: (_, action) async {
                      actions.add(action);
                      return false;
                    },
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpVisibleStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 600));
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a stock item without grams per piece names it and opens the '
      'editor from the line', (tester) async {
    final actions = <InventoryItemHubAction>[];
    await tester.pumpWidget(_buildHarness(actions: actions));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);

    await tester.ensureVisible(find.byKey(EatMissingValuesHint.buttonKey));
    await tester.tap(find.byKey(EatMissingValuesHint.buttonKey));
    await _pumpVisibleStep(tester);

    expect(actions, [InventoryItemHubAction.edit]);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
