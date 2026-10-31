import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_dashboard_edit_controller.g.dart';

/// Whether the diary dashboard is in edit mode, for every day page at once.
/// Not saved: the dashboard opens outside edit mode.
@riverpod
class DiaryDashboardEditController extends _$DiaryDashboardEditController {
  @override
  bool build() => false;

  /// Enters edit mode.
  void start() => state = true;

  /// Leaves edit mode.
  void finish() => state = false;
}
