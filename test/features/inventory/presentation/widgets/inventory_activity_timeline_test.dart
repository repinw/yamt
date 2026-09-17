import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_timeline.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('timeline renders household activity events', (tester) async {
    final repository = _FakeInventoryActivityEventRepository(
      <InventoryActivityEvent>[
        InventoryActivityEvent(
          id: 'event-1',
          type: InventoryActivityEventType.itemConsumed,
          actorUserId: 'user-1',
          actorDisplayName: 'Alex',
          happenedAt: DateTime(2026, 4, 7, 12),
          itemId: 'item-1',
          itemName: 'Milk',
          amount: 1,
          amountScale: 1,
          beforeQuantity: 2,
          afterQuantity: 1,
          beforeCurrentAmount: 0,
          afterCurrentAmount: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryActivityEventRepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InventoryActivityTimeline(
              includeHomeShellChrome: false,
              topChromeActions: <Widget>[],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Alex ate 1 item of Milk.'), findsOneWidget);
  });
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
