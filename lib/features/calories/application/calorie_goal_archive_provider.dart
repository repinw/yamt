import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_archive_provider.g.dart';

/// Goal cycles displayed by the Calories goal archive.
@riverpod
Future<List<TdeeAnalyticsGoalCycle>> calorieGoalArchive(Ref ref) async {
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  return TdeeCycleResolver.resolveGoalCycles(
    settings,
  ).where((cycle) => !cycle.isAllGoals).toList(growable: false);
}
