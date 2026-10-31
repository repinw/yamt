import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_catalog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

String _label(AppLocalizations l10n) => 'Tile';

Widget _build(DiaryTileArgs args) =>
    Text('${args.mode} ${args.size.name}', maxLines: 1);

DiaryDashboardTile _tile(
  String id, {
  List<DiaryTileSize> sizes = const [DiaryTileSize.s1x1],
  bool visible = true,
}) => DiaryDashboardTile(
  id: id,
  icon: Icons.circle,
  label: _label,
  sizes: sizes,
  defaultSize: sizes.first,
  modes: const [
    DiaryTileMode(id: 'one', icon: Icons.looks_one, label: _label),
    DiaryTileMode(id: 'two', icon: Icons.looks_two, label: _label),
  ],
  builder: _build,
  visibleByDefault: visible,
);

final List<DiaryDashboardTile> _catalog = [
  _tile('a', sizes: const [DiaryTileSize.s1x1, DiaryTileSize.s2x2]),
  _tile('b'),
  _tile('c'),
  _tile('hidden', visible: false),
];

const _prefsKey = 'diary_dashboard_layout_v1:anna';

Future<(ProviderContainer, AppPreferences)> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final user = _MockUser();
  when(() => user.uid).thenReturn('anna');
  final preferences = MemoryAppPreferences();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        diaryDashboardTilesProvider.overrideWithValue(_catalog),
        appPreferencesProvider.overrideWithValue(preferences),
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DiaryDashboard(day: DateTime(2026, 10, 31)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DiaryDashboard)),
  );
  return (container, preferences);
}

List<String> _order(ProviderContainer container) => [
  for (final t in container.read(diaryDashboardLayoutControllerProvider).tiles)
    t.id,
];

Future<void> _enterEditMode(WidgetTester tester) async {
  await tester.longPress(find.byKey(DiaryDashboardKeys.tile('a')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the default tiles in a row without edit chrome', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);

    expect(_order(container), ['a', 'b', 'c']);
    expect(find.byKey(DiaryDashboardKeys.done), findsNothing);
    final a = tester.getRect(find.byKey(DiaryDashboardKeys.tile('a')));
    final b = tester.getRect(find.byKey(DiaryDashboardKeys.tile('b')));
    expect(b.top, a.top);
    expect(b.left, greaterThan(a.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long press enters edit mode and "Fertig" leaves it', (
    tester,
  ) async {
    await _pump(tester);
    await _enterEditMode(tester);

    expect(find.byKey(DiaryDashboardKeys.done), findsOneWidget);
    expect(find.byKey(DiaryDashboardKeys.resize('a')), findsOneWidget);
    expect(find.byKey(DiaryDashboardKeys.resize('b')), findsNothing);

    await tester.tap(find.byKey(DiaryDashboardKeys.done));
    await tester.pumpAndSettle();
    expect(find.byKey(DiaryDashboardKeys.done), findsNothing);
  });

  testWidgets('dragging a tile onto another moves it there and saves', (
    tester,
  ) async {
    final (container, preferences) = await _pump(tester);
    final start = tester.getCenter(find.byKey(DiaryDashboardKeys.tile('a')));

    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    final target = tester.getCenter(find.byKey(DiaryDashboardKeys.tile('c')));
    await gesture.moveTo(target);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_order(container), ['b', 'c', 'a']);
    final saved = preferences.getStringSync(_prefsKey);
    expect(saved, isNotNull);
    final ids = [
      for (final t
          in (jsonDecode(saved!) as Map<String, dynamic>)['tiles']
              as List<dynamic>)
        (t as Map<String, dynamic>)['id'],
    ];
    expect(ids, ['b', 'c', 'a']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the corner handle snaps the tile to a bigger size', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);
    await _enterEditMode(tester);

    final handle = tester.getCenter(find.byKey(DiaryDashboardKeys.resize('a')));
    final cell = tester.getSize(find.byKey(DiaryDashboardKeys.tile('a')));
    final gesture = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(Offset(cell.width * 1.1, cell.height * 1.1));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      container.read(diaryDashboardLayoutControllerProvider).tiles.first.size,
      DiaryTileSize.s2x2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tile menu switches the mode and hides the tile', (
    tester,
  ) async {
    final (container, _) = await _pump(tester);
    await _enterEditMode(tester);

    await tester.tap(find.byKey(DiaryDashboardKeys.tile('b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryDashboardKeys.mode('two')));
    await tester.pumpAndSettle();
    expect(find.text('two s1x1'), findsOneWidget);

    await tester.tap(find.byKey(DiaryDashboardKeys.hide));
    await tester.pumpAndSettle();
    expect(_order(container), ['a', 'c']);
  });

  testWidgets('a hidden tile comes back from the add sheet; reset restores', (
    tester,
  ) async {
    final (container, preferences) = await _pump(tester);
    await _enterEditMode(tester);

    await tester.tap(find.byKey(DiaryDashboardKeys.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryDashboardKeys.addTile('hidden')));
    await tester.pumpAndSettle();
    expect(_order(container), ['a', 'b', 'c', 'hidden']);

    await tester.tap(find.byKey(DiaryDashboardKeys.reset));
    await tester.pumpAndSettle();
    expect(_order(container), ['a', 'b', 'c']);
    expect(preferences.getStringSync(_prefsKey), isNull);
  });
}
