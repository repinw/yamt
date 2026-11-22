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

import '../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

const _key = 'diary_dashboard_layout_v1:anna';

ProviderContainer _container(MemoryAppPreferences preferences) {
  final user = _MockUser();
  when(() => user.uid).thenReturn('anna');
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      authStateChangesProvider.overrideWithValue(AsyncData(user)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

DiaryDashboardLayout _layout(ProviderContainer c) =>
    c.read(diaryDashboardLayoutControllerProvider);

List<String> _shown(ProviderContainer c) => [
  for (final t in _layout(c).tiles) t.id,
];

DiaryTilePlacement _placement(String id) => DiaryTilePlacement.of(
  diaryDashboardTileSpecs.firstWhere((s) => s.id == id),
);

void main() {
  test('T1: never changed layout shows only the budget card', () {
    final container = _container(MemoryAppPreferences());

    expect(_shown(container), [DiaryTileIds.budget]);
    expect(
      _layout(container).hidden,
      containsAll([
        DiaryTileIds.weight,
        DiaryTileIds.meals,
        DiaryTileIds.kcal,
        DiaryTileIds.macros,
        DiaryTileIds.tdee,
        DiaryTileIds.dayType,
        DiaryTileIds.overdue,
      ]),
    );
  });

  test('T1: a saved layout with weight and meals keeps both shown', () {
    final saved = DiaryDashboardLayout(
      tiles: [
        _placement(DiaryTileIds.budget),
        _placement(DiaryTileIds.weight),
        _placement(DiaryTileIds.meals),
      ],
      hidden: const [],
    );
    final container = _container(
      MemoryAppPreferences(initialStrings: {_key: jsonEncode(saved.toJson())}),
    );

    expect(_shown(container), [
      DiaryTileIds.budget,
      DiaryTileIds.weight,
      DiaryTileIds.meals,
    ]);
  });

  test('T1: a saved layout without weight and meals keeps them hidden', () {
    final saved = DiaryDashboardLayout(
      tiles: [_placement(DiaryTileIds.budget)],
      hidden: const [DiaryTileIds.weight, DiaryTileIds.meals],
    );
    final container = _container(
      MemoryAppPreferences(initialStrings: {_key: jsonEncode(saved.toJson())}),
    );

    expect(_shown(container), [DiaryTileIds.budget]);
    expect(
      _layout(container).hidden,
      containsAll([DiaryTileIds.weight, DiaryTileIds.meals]),
    );
  });

  test('T1: adding the hidden weight and meals tiles shows them', () async {
    final container = _container(MemoryAppPreferences());
    final controller = container.read(
      diaryDashboardLayoutControllerProvider.notifier,
    );

    expect(await controller.show(DiaryTileIds.weight), isTrue);
    expect(await controller.show(DiaryTileIds.meals), isTrue);

    expect(_shown(container), [
      DiaryTileIds.budget,
      DiaryTileIds.weight,
      DiaryTileIds.meals,
    ]);
  });
}
