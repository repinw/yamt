import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calorie_overview_revision_provider.g.dart';

/// Global revision counter for diary mutations that affect day/week overviews.
@Riverpod(keepAlive: true)
class CalorieOverviewRevision extends _$CalorieOverviewRevision {
  @override
  int build() => 0;

  void markChanged() {
    state += 1;
  }
}
