import 'dart:developer' show log;

import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/data/diary_dashboard_layout_repository.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';

part 'diary_dashboard_layout_controller.g.dart';

const _logName = 'DiaryDashboardLayoutController';

/// The diary dashboard layout of the signed-in user, resolved against
/// [diaryDashboardTileSpecs]. Drags change it live; [save] stores it.
///
/// The actions that save return false when the layout was not saved; the
/// layout on screen keeps the change.
@riverpod
class DiaryDashboardLayoutController extends _$DiaryDashboardLayoutController {
  @override
  DiaryDashboardLayout build() {
    final repository = ref.watch(diaryDashboardLayoutRepositoryProvider);
    try {
      final saved = repository.cachedLayout();
      if (saved != null) return saved.resolve(diaryDashboardTileSpecs);
    } on FormatException catch (error, stackTrace) {
      log(
        'Stored diary dashboard layout is unreadable; showing the default.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    } on CheckedFromJsonException catch (error, stackTrace) {
      log(
        'Stored diary dashboard layout has the wrong shape; showing the '
        'default.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return DiaryDashboardLayout.initial(diaryDashboardTileSpecs);
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
  Future<bool> setMode(String id, String mode) {
    final tile = _placement(id);
    if (tile != null) state = state.update(tile.copyWith(mode: mode));
    return save();
  }

  /// Gives tile [id] the [size] and saves.
  Future<bool> setSize(String id, DiaryTileSize size) {
    resize(id, size);
    return save();
  }

  /// Hides tile [id] and saves.
  Future<bool> hide(String id) {
    state = state.hide(id);
    return save();
  }

  /// Shows the hidden tile [id] at the end and saves.
  Future<bool> show(String id) {
    final spec = diaryDashboardTileSpecs.where((s) => s.id == id).firstOrNull;
    if (spec != null) state = state.show(spec);
    return save();
  }

  /// Goes back to the default layout and forgets the saved one.
  Future<bool> reset() {
    state = DiaryDashboardLayout.initial(diaryDashboardTileSpecs);
    return _guard(
      'Failed to delete the diary dashboard layout.',
      (repository) => repository.deleteLayout(),
    );
  }

  /// Saves the current layout.
  Future<bool> save() {
    final layout = state;
    return _guard(
      'Failed to save the diary dashboard layout.',
      (repository) => repository.saveLayout(layout),
    );
  }

  Future<bool> _guard(
    String failure,
    Future<void> Function(DiaryDashboardLayoutRepository repository) write,
  ) async {
    final result = await AsyncValue.guard(
      () => write(ref.read(diaryDashboardLayoutRepositoryProvider)),
    );
    if (result case AsyncError(:final error, :final stackTrace)) {
      log(failure, name: _logName, error: error, stackTrace: stackTrace);
    }
    return !result.hasError;
  }

  DiaryTilePlacement? _placement(String id) =>
      state.tiles.where((t) => t.id == id).firstOrNull;
}
