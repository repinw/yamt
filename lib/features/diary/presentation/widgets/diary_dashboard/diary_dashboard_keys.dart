import 'package:material_ui/material_ui.dart';

/// Keys of the diary dashboard for tests.
abstract final class DiaryDashboardKeys {
  /// The dashboard.
  static const dashboard = Key('diary_dashboard');

  /// "Fertig" of the edit bar.
  static const done = Key('diary_dashboard_done');

  /// "Zurücksetzen" of the edit bar.
  static const reset = Key('diary_dashboard_reset');

  /// The add button of the edit bar.
  static const add = Key('diary_dashboard_add');

  /// "Ausblenden" in the tile sheet.
  static const hide = Key('diary_dashboard_hide');

  /// The slot of tile [id].
  static Key tile(String id) => Key('diary_dashboard_tile_$id');

  /// The menu button of tile [id] in edit mode.
  static Key menu(String id) => Key('diary_dashboard_menu_$id');

  /// The resize handle of tile [id] in edit mode.
  static Key resize(String id) => Key('diary_dashboard_resize_$id');

  /// The choice of mode [mode] in the tile sheet.
  static Key mode(String mode) => Key('diary_dashboard_mode_$mode');

  /// The choice of size [size] in the tile sheet.
  static Key size(String size) => Key('diary_dashboard_size_$size');

  /// The entry of hidden tile [id] in the add sheet.
  static Key addTile(String id) => Key('diary_dashboard_add_$id');
}
