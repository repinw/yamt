import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/product_search_hub/support/'
    'fake_product_search_sources.dart';
import '../../test/helpers/soft_keyboard_test_utils.dart';

const _openKey = Key('open_product_search');
const _searchFieldKey = Key('product_search_hub_search_field');
const _ownMealKey = Key('product_search_hub_search_result_manual-food-own');
const _freeRangeEggsKey = Key('product_search_hub_search_result_4000000000024');
const _eggsKey = Key('product_search_hub_search_result_4000000000031');
const _otherUsersMealKey = Key(
  'product_search_hub_search_result_manual-food-other',
);

class _MockUser extends Mock implements User;

/// Opens the product search signed in as `me`, with a shared catalog that
/// holds the AI meals of `me` and of another user, as Firestore returns them.
Widget _buildHarness() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () => context.push(AppRoutes.homeProductSearchHub),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => const ProductSearchHubPage(),
      ),
    ],
  );
  addTearDown(router.dispose);

  final user = _MockUser();
  when(() => user.uid).thenReturn('me');
  when(() => user.isAnonymous).thenReturn(false);
  // The recent items of the search read the Vorrat repository, which reaches
  // the user profile and Firestore; without them the Vorrat is empty.
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWithValue(AsyncData<User?>(user)),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWithValue(const AsyncData(null)),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 12)),
      globalFoodItemRepositoryProvider.overrideWithValue(
        FakeGlobalFoodItemRepository(
          results: [
            catalogFood(
              id: 'manual-food-other',
              name: 'Eier und Rosenbrötchen mit Frischkäse',
              createdBy: 'other-user',
            ),
            catalogFood(
              id: 'manual-food-own',
              name: 'Eier mit Speck',
              createdBy: 'me',
            ),
          ],
        ),
      ),
      offProductSearchRepositoryProvider.overrideWithValue(
        const FakeOffProductSearchRepository(
          results: [
            OffProductSearchResult(
              code: '4000000000024',
              name: 'Freilandeier',
              score: 1,
            ),
            OffProductSearchResult(
              code: '4000000000031',
              name: 'Eier',
              score: 1,
            ),
          ],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('de'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Shows the next frames for [observeFor]: real time on a device, fake
/// time in a widget test.
Future<void> _pumpVisibleStep(
  WidgetTester tester, {
  Duration observeFor = const Duration(milliseconds: 600),
}) async {
  await tester.pump();
  await tester.pump(observeFor);
}

/// Waits until the soft keyboard is gone again, then shows the screen.
Future<void> _waitForKeyboardClosed(WidgetTester tester) async {
  await waitForKeyboardClosed(tester);
  await _pumpVisibleStep(tester);
}

double _top(WidgetTester tester, Key key) {
  return tester.getTopLeft(find.byKey(key)).dy;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('the AI meal of another user comes after the plain products, '
      'the own AI meal stays found (#655)', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    await tester.enterText(find.byKey(_searchFieldKey), 'Eier');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _waitForKeyboardClosed(tester);

    for (final key in [
      _ownMealKey,
      _freeRangeEggsKey,
      _eggsKey,
      _otherUsersMealKey,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(
      _top(tester, _ownMealKey),
      lessThan(_top(tester, _freeRangeEggsKey)),
    );
    expect(_top(tester, _freeRangeEggsKey), lessThan(_top(tester, _eggsKey)));
    expect(_top(tester, _eggsKey), lessThan(_top(tester, _otherUsersMealKey)));
    expect(tester.takeException(), isNull);
  });
}
