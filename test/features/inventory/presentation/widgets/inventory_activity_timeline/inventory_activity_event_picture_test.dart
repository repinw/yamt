import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_event_picture.dart';

const _imageUrl = 'https://example.com/milk.png';

InventoryActivityEvent _event({
  String? imageUrl,
  InventoryActivityEventType type = InventoryActivityEventType.itemConsumed,
}) {
  return InventoryActivityEvent(
    id: 'event-1',
    type: type,
    actorUserId: 'user-1',
    actorDisplayName: 'Alex',
    happenedAt: DateTime(2026, 4, 7, 12),
    itemId: 'item-1',
    itemName: 'Milk',
    itemImageUrl: imageUrl,
    amount: 1,
    amountScale: 1,
    beforeQuantity: 2,
    afterQuantity: 1,
    beforeCurrentAmount: 0,
    afterCurrentAmount: 0,
  );
}

Future<void> _pump(
  WidgetTester tester,
  InventoryActivityEvent event, {
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: InventoryActivityEventPicture(event: event, tiltLeft: true),
        ),
      ),
    ),
  );
}

Finder _badge() =>
    find.byKey(InventoryActivityEventPicture.badgeKey('event-1'));

void main() {
  testWidgets('shows the food picture with the action badge', (tester) async {
    await _pump(tester, _event(imageUrl: _imageUrl));

    final picture = find.byKey(
      InventoryActivityEventPicture.pictureKey('event-1'),
    );
    expect(picture, findsOneWidget);
    final image = tester.widget<AppCachedNetworkImage>(
      find.descendant(
        of: picture,
        matching: find.byType(AppCachedNetworkImage),
      ),
    );
    expect(image.imageUrl, _imageUrl);
    expect(
      find.descendant(of: _badge(), matching: find.byIcon(Icons.restaurant)),
      findsOneWidget,
    );
    expect(
      find.byKey(InventoryActivityEventPicture.iconKey('event-1')),
      findsNothing,
    );
  });

  testWidgets('puts the badge small at the lower right of the picture', (
    tester,
  ) async {
    await _pump(
      tester,
      _event(
        imageUrl: _imageUrl,
        type: InventoryActivityEventType.itemDiscarded,
      ),
    );

    final tile = tester.getRect(find.byType(EatImageTile));
    final badge = tester.getRect(_badge());
    expect(badge.width, lessThan(tile.width / 2));
    expect(badge.center.dx, greaterThan(tile.center.dx));
    expect(badge.center.dy, greaterThan(tile.center.dy));
    expect(
      find.descendant(
        of: _badge(),
        matching: find.byIcon(Icons.delete_outline),
      ),
      findsOneWidget,
    );
  });

  for (final imageUrl in <String?>[null, '', 'not an address']) {
    testWidgets('shows only the action icon without a picture ($imageUrl)', (
      tester,
    ) async {
      await _pump(
        tester,
        _event(imageUrl: imageUrl, type: InventoryActivityEventType.itemAdded),
      );

      final icon = find.byKey(InventoryActivityEventPicture.iconKey('event-1'));
      expect(icon, findsOneWidget);
      expect(tester.widget<Icon>(icon).icon, Icons.add);
      expect(
        find.byKey(InventoryActivityEventPicture.pictureKey('event-1')),
        findsNothing,
      );
      expect(_badge(), findsNothing);
      expect(find.byType(AppCachedNetworkImage), findsNothing);
    });
  }

  for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
    testWidgets('the badge uses the accent of the ${theme.brightness} theme', (
      tester,
    ) async {
      await _pump(tester, _event(imageUrl: _imageUrl), theme: theme);

      final colors = theme.colorScheme;
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: _badge(), matching: find.byType(DecoratedBox)),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, colors.primary);
      expect((decoration.border! as Border).top.color, colors.surface);
      final icon = tester.widget<Icon>(
        find.descendant(of: _badge(), matching: find.byType(Icon)),
      );
      expect(icon.color, colors.onPrimary);
    });
  }

  testWidgets('adds nothing to the semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _event(imageUrl: _imageUrl));
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    semantics.dispose();
  });
}
