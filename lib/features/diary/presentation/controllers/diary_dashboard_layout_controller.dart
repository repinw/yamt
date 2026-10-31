import 'dart:developer' show log;

import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/data/diary_dashboard_layout_repository.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_catalog.dart';

part 'diary_dashboard_layout_controller.g.dart';

final List<DiaryTileSpec> _catalogSpecs = [
  for (final tile in diaryDashboardCatalog) tile.spec,
];

/// The diary dashboard layout of the signed-in user, resolved against the
/// tile catalog. Drags change it live; [save] stores it.
@riverpod
class DiaryDashboardLayoutController extends _$DiaryDashboardLayoutController {
  @override
  DiaryDashboardLayout build() {
    final repository = ref.watch(diaryDashboardLayoutRepositoryProvider);
    try {
      final saved = repository.cachedLayout();
      if (saved != null) return saved.resolve(_catalogSpecs);
    } on FormatException catch (error, stackTrace) {
      log(
        'Stored diary dashboard layout is unreadable; showing the default.',
        error: error,
        stackTrace: stackTrace,
      );
    } on CheckedFromJsonException catch (error, stackTrace) {
      log(
        'Stored diary dashboard layout has the wrong shape; showing the '
        'default.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return DiaryDashboardLayout.initial(_catalogSpecs);
  }

  /// Moves tile [id] to [index] without saving, for a running drag.
  void move(String id, int index) => state = state.move(id, index);

  /// Gives tile [id] the [size] without saving, for a running resize.
  void resize(String id, DiaryTileSize size) {
    final tile = _placement(id);
    if (tile == null || tile.size == size) return;
    state = state.update(tile.copyWith(size: size));
  }

  /// Switches tile [id] to display mode [mode] and saves.
  Future<void> setMode(String id, String mode) async {
    final tile = _placement(id);
    if (tile == null) return;
    state = state.update(tile.copyWith(mode: mode));
    await save();
  }

  /// Gives tile [id] the [size] and saves.
  Future<void> setSize(String id, DiaryTileSize size) async {
    resize(id, size);
    await save();
  }

  /// Hides tile [id] and saves.
  Future<void> hide(String id) async {
    state = state.hide(id);
    await save();
  }

  /// Shows the hidden tile [id] at the end and saves.
  Future<void> show(String id) async {
    final spec = _catalogSpecs.where((s) => s.id == id).firstOrNull;
    if (spec == null) return;
    state = state.show(spec);
    await save();
  }

  /// Goes back to the default layout and forgets the saved one.
  Future<void> reset() async {
    state = DiaryDashboardLayout.initial(_catalogSpecs);
    await ref.read(diaryDashboardLayoutRepositoryProvider).deleteLayout();
  }

  /// Saves the current layout.
  Future<void> save() =>
      ref.read(diaryDashboardLayoutRepositoryProvider).saveLayout(state);

  DiaryTilePlacement? _placement(String id) =>
      state.tiles.where((t) => t.id == id).firstOrNull;
}
