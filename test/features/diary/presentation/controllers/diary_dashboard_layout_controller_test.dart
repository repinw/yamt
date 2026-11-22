import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

const _key = 'diary_dashboard_layout_v1:anna';

ProviderContainer _container(
  AppPreferences preferences, {
  bool signedIn = true,
}) {
  final user = _MockUser();
  when(() => user.uid).thenReturn('anna');
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      authStateChangesProvider.overrideWithValue(
        AsyncData(signedIn ? user : null),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

DiaryDashboardLayoutController _controller(ProviderContainer container) =>
    container.read(diaryDashboardLayoutControllerProvider.notifier);

List<String> _ids(ProviderContainer container) => [
  for (final t in container.read(diaryDashboardLayoutControllerProvider).tiles)
    t.id,
];

void main() {
  test('starts with the default layout of the tile specs', () {
    final container = _container(MemoryAppPreferences());

    expect(
      container.read(diaryDashboardLayoutControllerProvider),
      DiaryDashboardLayout.initial(diaryDashboardTileSpecs),
    );
    expect(_ids(container), [DiaryTileIds.budget]);
  });

  test('reads the saved layout and sorts in tiles it does not know', () {
    const saved = DiaryDashboardLayout(
      tiles: [
        DiaryTilePlacement(
          id: DiaryTileIds.meals,
          size: DiaryTileSize.s2x2,
          mode: DiaryTileModes.list,
        ),
      ],
      hidden: [DiaryTileIds.budget],
    );
    final container = _container(
      MemoryAppPreferences(initialStrings: {_key: jsonEncode(saved.toJson())}),
    );

    expect(_ids(container), [DiaryTileIds.meals]);
    expect(
      container.read(diaryDashboardLayoutControllerProvider).tiles.last,
      saved.tiles.single,
    );
    expect(
      container.read(diaryDashboardLayoutControllerProvider).hidden,
      containsAll([
        DiaryTileIds.budget,
        DiaryTileIds.weight,
        DiaryTileIds.kcal,
        DiaryTileIds.macros,
        DiaryTileIds.tdee,
        DiaryTileIds.dayType,
        DiaryTileIds.overdue,
      ]),
    );
  });

  test('an unreadable saved layout shows the default', () {
    final container = _container(
      MemoryAppPreferences(initialStrings: {_key: '{"tiles": 3}'}),
    );

    expect(
      container.read(diaryDashboardLayoutControllerProvider),
      DiaryDashboardLayout.initial(diaryDashboardTileSpecs),
    );
  });

  test('changes save the layout; reset forgets it', () async {
    final preferences = MemoryAppPreferences();
    final container = _container(preferences);
    final controller = _controller(container);

    expect(await controller.show(DiaryTileIds.weight), isTrue);
    expect(await controller.hide(DiaryTileIds.weight), isTrue);
    expect(await controller.show(DiaryTileIds.kcal), isTrue);
    expect(
      await controller.setMode(DiaryTileIds.kcal, DiaryTileModes.ring),
      isTrue,
    );
    expect(
      await controller.setSize(DiaryTileIds.kcal, DiaryTileSize.s2x2),
      isTrue,
    );

    final saved = DiaryDashboardLayout.fromJson(
      jsonDecode(preferences.getStringSync(_key)!) as Map<String, dynamic>,
    );
    expect(saved, container.read(diaryDashboardLayoutControllerProvider));
    expect(
      saved.tiles.last,
      const DiaryTilePlacement(
        id: DiaryTileIds.kcal,
        size: DiaryTileSize.s2x2,
        mode: DiaryTileModes.ring,
      ),
    );
    expect(saved.hidden, contains(DiaryTileIds.weight));

    expect(await controller.reset(), isTrue);
    expect(preferences.getStringSync(_key), isNull);
    expect(
      container.read(diaryDashboardLayoutControllerProvider),
      DiaryDashboardLayout.initial(diaryDashboardTileSpecs),
    );
  });

  test('a move and a resize change the layout without saving', () async {
    final preferences = MemoryAppPreferences();
    final container = _container(preferences);
    final controller = _controller(container);
    await controller.show(DiaryTileIds.weight);
    await controller.show(DiaryTileIds.meals);
    await preferences.remove(_key);

    controller
      ..move(DiaryTileIds.meals, 0)
      ..resize(DiaryTileIds.weight, DiaryTileSize.s1x1);

    expect(_ids(container).first, DiaryTileIds.meals);
    expect(
      container
          .read(diaryDashboardLayoutControllerProvider)
          .tiles
          .firstWhere((t) => t.id == DiaryTileIds.weight)
          .size,
      DiaryTileSize.s1x1,
    );
    expect(preferences.getStringSync(_key), isNull);
  });

  test('signed out, a change stays on screen and reports false', () async {
    final container = _container(MemoryAppPreferences(), signedIn: false);
    final controller = _controller(container);

    expect(await controller.show(DiaryTileIds.weight), isFalse);
    expect(_ids(container), contains(DiaryTileIds.weight));
    expect(await controller.hide(DiaryTileIds.weight), isFalse);
    expect(_ids(container), isNot(contains(DiaryTileIds.weight)));
    expect(await controller.reset(), isFalse);
  });
}
