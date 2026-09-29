import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

part 'progress_scope_controller.g.dart';

/// Which goals the Fortschritt tab shows: the current one or all.
@riverpod
class ProgressScopeController extends _$ProgressScopeController {
  @override
  ProgressScope build() => ProgressScope.goal;

  /// The shown scope.
  ProgressScope get scope => state;

  /// Shows the goals of the given scope.
  set scope(ProgressScope value) => state = value;
}
