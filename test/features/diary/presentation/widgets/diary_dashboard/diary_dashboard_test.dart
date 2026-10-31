import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

String _label(AppLocalizations l10n) => 'Tile';

Widget _build(DiaryTileArgs args) {
  final text = Text('${args.mode} ${args.size.name}', maxLines: 1);
  return args.size.isWide ? SizedBox(height: 120, child: text) : text;
}

/// A plain tile for each real spec, so the grid runs without tile data.
final List<DiaryDashboardTile> _tiles = [
  for (final spec in diaryDashboardTileSpecs)
    DiaryDashboardTile(
      spec: spec,
      icon: Icons.circle,
      label: _label,
      modes: [
        for (final mode in spec.modes)
          DiaryTileMode(id: mode, icon: Icons.circle, label: _label),
      ],
      builder: _build,
    ),
];

const List<String> _defaultOrder = [
  DiaryTileIds.budget,
  DiaryTileIds.weight,
  DiaryTileIds.meals,
];

const _prefsKey = 'diary_dashboard_layout_v1:anna';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

Future<(ProviderContainer, AppPreferences, ScrollController)> _pump(
  WidgetTester tester, {
  bool signedIn = true,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final user = _MockUser();
  when(() => user.uid).thenReturn('anna');
  final preferences = MemoryAppPreferences();
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        authStateChangesProvider.overrideWithValue(
          AsyncData(signedIn ? user : null),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DiaryDashboard(day: DateTime(2026, 10, 31), tiles: _tiles),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DiaryDashboard)),
  );
  return (container, preferences, scroll);
}

List<String> _order(ProviderContainer container) => [
  for (final t in container.read(diaryDashboardLayoutControllerProvider).tiles)
    t.id,
];

Finder _tile(String id) => find.byKey(DiaryDashboardKeys.tile(id));

Future<void> _enterEditMode(WidgetTester tester) async {
  await tester.longPress(_tile(DiaryTileIds.weight));
  await tester.pumpAndSettle();
}

/// Holds tile [id] in edit mode until it follows the finger.
Future<TestGesture> _holdInEditMode(WidgetTester tester, String id) async {
  final gesture = await tester.startGesture(tester.getCenter(_tile(id)));
  await tester.pump(
    AppDashboard.editDragDelay + const Duration(milliseconds: 50),
  );
  return gesture;
}

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The visible disc of the edit button [button], inside its tap area.
Finder _disc(Key button) => find.descendant(
  of: find.byKey(button),
  matching: find.byType(DecoratedBox),
);

void main() {
  testWidgets('shows the default tiles without edit chrome', (tester) async {
    final (container, _, _) = await _pump(tester);

    expect(_order(container), _defaultOrder);
    expect(find.byKey(DiaryDashboardKeys.done), findsNothing);
    final weight = tester.getRect(_tile(DiaryTileIds.weight));
    final meals = tester.getRect(_tile(DiaryTileIds.meals));
    expect(meals.top, greaterThan(weight.bottom - 1));
    expect(weight.width, lessThan(meals.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long press enters edit mode and "Fertig" leaves it', (
    tester,
  ) async {
    await _pump(tester);
    await _enterEditMode(tester);

    expect(find.byKey(DiaryDashboardKeys.done), findsOneWidget);
    expect(
      find.byKey(DiaryDashboardKeys.resize(DiaryTileIds.weight)),
      findsOneWidget,
    );
    expect(
      find.byKey(DiaryDashboardKeys.resize(DiaryTileIds.budget)),
      findsNothing,
    );

    await tester.tap(find.byKey(DiaryDashboardKeys.done));
    await tester.pumpAndSettle();
    expect(find.byKey(DiaryDashboardKeys.done), findsNothing);
  });

  testWidgets('the edit buttons fill the tile corners and keep full taps', (
    tester,
  ) async {
    await _pump(tester);
    await _enterEditMode(tester);

    final tile = tester.getRect(_tile(DiaryTileIds.weight));
    for (final (button, corner) in [
      (DiaryDashboardKeys.menu(DiaryTileIds.weight), Alignment.topRight),
      (DiaryDashboardKeys.resize(DiaryTileIds.weight), Alignment.bottomRight),
    ]) {
      expect(
        tester.getSize(find.byKey(button)),
        const Size.square(AppSizes.minTapTarget),
        reason: '$button',
      );
      expect(
        tester.getRect(_disc(button)),
        rectMoreOrLessEquals(
          corner.inscribe(const Size.square(AppDashboard.tileRadius), tile),
        ),
        reason: '$button',
      );
    }
  });

  testWidgets('dragging a tile onto another moves it there and saves', (
    tester,
  ) async {
    final (container, preferences, _) = await _pump(tester);
    final mealsTop = tester.getRect(_tile(DiaryTileIds.meals)).top;

    final gesture = await tester.startGesture(
      tester.getCenter(_tile(DiaryTileIds.weight)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    // The edit bar waits for the finger, so no tile moves under it.
    expect(find.byKey(DiaryDashboardKeys.done), findsNothing);
    expect(tester.getRect(_tile(DiaryTileIds.meals)).top, mealsTop);

    await gesture.moveTo(tester.getCenter(_tile(DiaryTileIds.meals)));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    const moved = [
      DiaryTileIds.budget,
      DiaryTileIds.meals,
      DiaryTileIds.weight,
    ];
    expect(_order(container), moved);
    expect(find.byKey(DiaryDashboardKeys.done), findsOneWidget);
    final saved = preferences.getStringSync(_prefsKey);
    expect(saved, isNotNull);
    final ids = [
      for (final t
          in (jsonDecode(saved!) as Map<String, dynamic>)['tiles']
              as List<dynamic>)
        (t as Map<String, dynamic>)['id'],
    ];
    expect(ids, moved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tile held at the bottom edge scrolls the page on', (
    tester,
  ) async {
    final (_, _, scroll) = await _pump(tester);
    final start = tester.getCenter(_tile(DiaryTileIds.weight));

    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(Offset(start.dx, 790));
    await _pumpFrames(tester, 5);
    final first = scroll.offset;
    expect(first, greaterThan(0));

    // The finger rests at the edge, and the page keeps scrolling.
    await _pumpFrames(tester, 20);
    expect(scroll.offset, greaterThan(first + 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Fertig" during a drag drops the tile where it is', (
    tester,
  ) async {
    final (container, preferences, _) = await _pump(tester);
    await _enterEditMode(tester);

    final drag = await _holdInEditMode(tester, DiaryTileIds.weight);
    await drag.moveTo(tester.getCenter(_tile(DiaryTileIds.meals)));
    await tester.pumpAndSettle();
    // A second finger.
    await tester.tap(find.byKey(DiaryDashboardKeys.done));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect(_order(container).last, DiaryTileIds.weight);
    expect(preferences.getStringSync(_prefsKey), isNotNull);
    // The drag is over, so a long press arranges again.
    await _enterEditMode(tester);
    expect(find.byKey(DiaryDashboardKeys.done), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reset that drops the dragged tile ends the drag', (
    tester,
  ) async {
    final (container, _, _) = await _pump(tester);
    await _enterEditMode(tester);
    await tester.tap(find.byKey(DiaryDashboardKeys.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryDashboardKeys.addTile(DiaryTileIds.kcal)));
    await tester.pumpAndSettle();

    final drag = await _holdInEditMode(tester, DiaryTileIds.kcal);
    await drag.moveBy(const Offset(0, -20));
    await tester.pump();
    // A second finger.
    await tester.tap(find.byKey(DiaryDashboardKeys.reset));
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();
    expect(_order(container), _defaultOrder);

    // The next drag moves a tile.
    final next = await _holdInEditMode(tester, DiaryTileIds.weight);
    await next.moveTo(tester.getCenter(_tile(DiaryTileIds.meals)));
    await tester.pumpAndSettle();
    await next.up();
    await tester.pumpAndSettle();
    expect(_order(container).last, DiaryTileIds.weight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a resize handle waits while another tile is dragged', (
    tester,
  ) async {
    final (container, _, _) = await _pump(tester);
    await _enterEditMode(tester);
    final handle = tester.getCenter(
      find.byKey(DiaryDashboardKeys.resize(DiaryTileIds.weight)),
    );
    final cell = tester.getSize(_tile(DiaryTileIds.weight));

    final drag = await _holdInEditMode(tester, DiaryTileIds.meals);
    // A second finger pulls the weight tile's handle as far as a 2×2 needs.
    final resize = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 20));
    await resize.moveBy(Offset(0, cell.height * 1.1));
    await tester.pump();
    await resize.up();
    await drag.up();
    await tester.pumpAndSettle();

    expect(
      container
          .read(diaryDashboardLayoutControllerProvider)
          .tiles
          .firstWhere((t) => t.id == DiaryTileIds.weight)
          .size,
      DiaryTileSize.s2x1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the corner handle snaps the tile to a bigger size', (
    tester,
  ) async {
    final (container, _, _) = await _pump(tester);
    await _enterEditMode(tester);

    final handle = tester.getCenter(
      find.byKey(DiaryDashboardKeys.resize(DiaryTileIds.weight)),
    );
    final cell = tester.getSize(_tile(DiaryTileIds.weight));
    final gesture = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(Offset(0, cell.height * 1.1));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      container
          .read(diaryDashboardLayoutControllerProvider)
          .tiles
          .firstWhere((t) => t.id == DiaryTileIds.weight)
          .size,
      DiaryTileSize.s2x2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tile menu switches the mode and hides the tile', (
    tester,
  ) async {
    final (container, _, _) = await _pump(tester);
    await _enterEditMode(tester);

    await tester.tap(_tile(DiaryTileIds.weight));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(DiaryDashboardKeys.mode(DiaryTileModes.sparkline)),
    );
    await tester.pumpAndSettle();
    expect(find.text('sparkline s2x1'), findsOneWidget);

    await tester.tap(find.byKey(DiaryDashboardKeys.hide));
    await tester.pumpAndSettle();
    expect(_order(container), [DiaryTileIds.budget, DiaryTileIds.meals]);
  });

  testWidgets('a hidden tile comes back from the add sheet; reset restores', (
    tester,
  ) async {
    final (container, preferences, _) = await _pump(tester);
    await _enterEditMode(tester);

    await tester.tap(find.byKey(DiaryDashboardKeys.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryDashboardKeys.addTile(DiaryTileIds.kcal)));
    await tester.pumpAndSettle();
    expect(_order(container), [..._defaultOrder, DiaryTileIds.kcal]);

    await tester.tap(find.byKey(DiaryDashboardKeys.reset));
    await tester.pumpAndSettle();
    expect(_order(container), _defaultOrder);
    expect(preferences.getStringSync(_prefsKey), isNull);
  });

  testWidgets('a change that was not saved says so', (tester) async {
    final (container, _, _) = await _pump(tester, signedIn: false);
    await _enterEditMode(tester);

    await tester.tap(_tile(DiaryTileIds.weight));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryDashboardKeys.hide));
    await tester.pumpAndSettle();

    expect(_order(container), isNot(contains(DiaryTileIds.weight)));
    expect(find.text(_l10n.diaryDashboardSaveFailed), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
