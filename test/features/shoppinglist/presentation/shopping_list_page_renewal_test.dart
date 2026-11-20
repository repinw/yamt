import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_shopping_shelf_choice_repository.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../support/fake_shopping_list_repository.dart';

void main() {
  testWidgets('opening the list page renews the entries that are due', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 19, 12);
    final repository = FakeShoppingListRepository(
      initialItems: [
        ShoppingListItem(
          id: 'milch',
          name: 'Milch',
          normalizedName: 'milch',
          normalizedBrand: '',
          quantity: 1,
          estimatedUnitPrice: 0,
          isDone: true,
          repeatEveryDays: 7,
          nextDueDate: DateTime(2026, 11, 20),
        ),
      ],
    );
    final shelves = FakeShoppingShelfChoiceRepository();
    addTearDown(shelves.dispose);
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(repository),
        shoppingShelfChoiceRepositoryProvider.overrideWithValue(shelves),
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        appUpdateStatusProvider.overrideWith((ref) => const Stream.empty()),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    // The list is loaded and alive before the page opens, as in the app.
    final keepAlive = container.listen(
      shoppingListControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    await tester.pump();
    await tester.pump();
    expect(keepAlive.read().requireValue.single.isDone, isTrue);

    now = DateTime(2026, 11, 20, 8);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShoppingListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ShoppingListPageKeys.tile('milch')), findsOneWidget);
    expect(repository.savedItems.single.isDone, isFalse);
  });
}
