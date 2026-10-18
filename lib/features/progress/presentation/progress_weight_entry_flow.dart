import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';

/// Opens the weight entry, which adds a weighing of today, filled with the
/// newest weighing.
///
/// It saves through the diary weight flow, so everything that depends on the
/// weight refreshes as after a weigh-in in the diary, such as the weight
/// trend and the goal.
Future<void> showProgressWeightEntry(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  // Keeps the auto-dispose weight flow alive while the dialog is open, so the
  // save still reaches the providers that depend on the weight.
  final subscription = container.listen(
    diaryWeightTrackingFlowProvider,
    (_, _) {},
  );
  try {
    final today = normalizeLocalDay(container.read(clockProvider)());
    await subscription.read().showDialogForDay(
      context: context,
      selectedDay: today,
      day: today,
    );
  } finally {
    subscription.close();
  }
}
