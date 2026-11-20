import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_open_count.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_header_tool.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_shopping_list_repository.dart';

ShoppingListItem _item(
  String id, {
  bool isDone = false,
  bool isArchived = false,
  bool isPrivate = false,
}) {
  return ShoppingListItem(
    id: id,
    name: id,
    normalizedName: id,
    normalizedBrand: '',
    quantity: 1,
    estimatedUnitPrice: 1,
    isDone: isDone,
    isArchived: isArchived,
    isPrivate: isPrivate,
  );
}

Future<void> _pump(
  WidgetTester tester,
  FakeShoppingListRepository repository, {
  bool onlyWithOpenEntries = false,
  bool settle = true,
}) async {
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShoppingHeaderTool(onlyWithOpenEntries: onlyWithOpenEntries),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

FakeShoppingListRepository _repository(List<ShoppingListItem> items) =>
    FakeShoppingListRepository(initialItems: items);

FakeShoppingListRepository _failingRepository() => FakeShoppingListRepository(
  onReadAll: () async => throw StateError('list unreadable'),
);

/// A repository whose first read never answers until the test ends.
FakeShoppingListRepository _loadingRepository() {
  final never = Completer<List<ShoppingListItem>>();
  addTearDown(() => never.complete(const []));
  return FakeShoppingListRepository(onReadAll: () => never.future);
}

void main() {
  testWidgets('onlyWithOpenEntries hides the tool at 0 open entries', (
    tester,
  ) async {
    await _pump(
      tester,
      _repository([_item('a', isDone: true), _item('b', isArchived: true)]),
      onlyWithOpenEntries: true,
    );

    expect(find.byType(HomeHeaderTool), findsNothing);
  });

  testWidgets('onlyWithOpenEntries shows the tool with the open count', (
    tester,
  ) async {
    await _pump(
      tester,
      _repository([
        _item('a'),
        _item('b', isPrivate: true),
        _item('c', isDone: true),
      ]),
      onlyWithOpenEntries: true,
    );

    expect(find.byType(HomeHeaderTool), findsOneWidget);
    expect(find.text('Einkauf'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('without the flag the tool stays at 0 and shows no badge', (
    tester,
  ) async {
    await _pump(tester, _repository(const []));

    expect(find.byType(HomeHeaderTool), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('a failed read shows the tool without a badge', (tester) async {
    await _pump(tester, _failingRepository());

    expect(find.byType(HomeHeaderTool), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('a failed read keeps the tool with onlyWithOpenEntries', (
    tester,
  ) async {
    await _pump(tester, _failingRepository(), onlyWithOpenEntries: true);

    expect(find.byType(HomeHeaderTool), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('while the list loads the tool shows no badge', (tester) async {
    await _pump(tester, _loadingRepository(), settle: false);

    expect(find.byType(HomeHeaderTool), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('while the list loads onlyWithOpenEntries hides the tool', (
    tester,
  ) async {
    await _pump(
      tester,
      _loadingRepository(),
      onlyWithOpenEntries: true,
      settle: false,
    );

    expect(find.byType(HomeHeaderTool), findsNothing);
  });

  testWidgets('openShoppingListCount counts open entries of both lists', (
    tester,
  ) async {
    await _pump(
      tester,
      _repository([
        _item('household'),
        _item('private', isPrivate: true),
        _item('household-ticked', isDone: true),
        _item('private-ticked', isPrivate: true, isDone: true),
        _item('archived', isArchived: true),
      ]),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShoppingHeaderTool)),
    );

    expect(container.read(openShoppingListCountProvider).value, 2);
  });

  testWidgets('openShoppingListCount is an error, not 0, when unreadable', (
    tester,
  ) async {
    await _pump(tester, _failingRepository());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShoppingHeaderTool)),
    );

    expect(container.read(openShoppingListCountProvider).hasError, isTrue);
  });
}
