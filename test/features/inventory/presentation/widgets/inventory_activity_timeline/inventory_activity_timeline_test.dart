import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_top_bar.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_event_picture.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_timeline.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('timeline renders household activity events', (tester) async {
    await _pumpTimeline(tester, [_event(id: 'event-1', itemName: 'Milk')]);

    expect(find.text('Alex ate 1 item of Milk.'), findsOneWidget);
  });

  testWidgets('a row shows the food picture with the action badge, or only '
      'the action icon without a picture', (tester) async {
    await _pumpTimeline(tester, [
      _event(
        id: 'with-picture',
        itemName: 'Milk',
        imageUrl: 'https://example.com/milk.png',
      ),
      _event(
        id: 'without-picture',
        itemName: 'Bread',
        type: InventoryActivityEventType.itemAdded,
      ),
    ]);

    final pictureRow = find.byKey(
      InventoryActivityTimeline.rowKey('with-picture'),
    );
    expect(
      find.descendant(
        of: pictureRow,
        matching: find.byKey(
          InventoryActivityEventPicture.pictureKey('with-picture'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(InventoryActivityEventPicture.badgeKey('with-picture')),
        matching: find.byIcon(Icons.restaurant),
      ),
      findsOneWidget,
    );

    final iconRow = find.byKey(
      InventoryActivityTimeline.rowKey('without-picture'),
    );
    expect(
      find.descendant(
        of: iconRow,
        matching: find.byKey(
          InventoryActivityEventPicture.iconKey('without-picture'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: iconRow, matching: find.byIcon(Icons.add)),
      findsOneWidget,
    );
    expect(
      find.byKey(InventoryActivityEventPicture.badgeKey('without-picture')),
      findsNothing,
    );
  });

  testWidgets('rows with and without a picture announce the action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpTimeline(tester, [
      _event(
        id: 'with-picture',
        itemName: 'Milk',
        imageUrl: 'https://example.com/milk.png',
      ),
      _event(
        id: 'without-picture',
        itemName: 'Bread',
        type: InventoryActivityEventType.itemDiscarded,
      ),
    ]);

    // The row reads its sentence and time; the picture adds nothing.
    expect(
      _rowLabel(tester, 'with-picture'),
      'Alex ate 1 item of Milk.\n12:00',
    );
    expect(
      _rowLabel(tester, 'without-picture'),
      'Alex discarded 1 item of Bread.\n12:00',
    );
    semantics.dispose();
  });

  testWidgets('the header stays below the status bar', (tester) async {
    tester.view.padding = FakeViewPadding(
      top: 40 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);

    await _pumpTimeline(tester, const [], includeHomeShellChrome: true);

    expect(tester.getTopLeft(find.byType(HomeTopBar)).dy, 40);
  });
}

String _rowLabel(WidgetTester tester, String eventId) {
  return tester
      .getSemantics(find.byKey(InventoryActivityTimeline.rowKey(eventId)))
      .label;
}

InventoryActivityEvent _event({
  required String id,
  required String itemName,
  InventoryActivityEventType type = InventoryActivityEventType.itemConsumed,
  String? imageUrl,
}) {
  return InventoryActivityEvent(
    id: id,
    type: type,
    actorUserId: 'user-1',
    actorDisplayName: 'Alex',
    happenedAt: DateTime(2026, 4, 7, 12),
    itemId: 'item-$id',
    itemName: itemName,
    itemImageUrl: imageUrl,
    amount: 1,
    amountScale: 1,
    beforeQuantity: 2,
    afterQuantity: 1,
    beforeCurrentAmount: 0,
    afterCurrentAmount: 0,
  );
}

Future<void> _pumpTimeline(
  WidgetTester tester,
  List<InventoryActivityEvent> events, {
  bool includeHomeShellChrome = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryActivityEventRepositoryProvider.overrideWithValue(
          _FakeInventoryActivityEventRepository(events),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InventoryActivityTimeline(
            includeHomeShellChrome: includeHomeShellChrome,
            topChromeActions: const <Widget>[],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  const new(this.events);

  final List<InventoryActivityEvent> events;

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    return true;
  }

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return Stream<List<InventoryActivityEvent>>.value(events);
  }
}
