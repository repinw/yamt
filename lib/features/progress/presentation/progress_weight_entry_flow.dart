import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/progress/application/progress_weight_provider.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_scope_controller.dart';

/// Opens the weight entry for today, filled with the last weigh-in of the
/// weight chart.
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
    final initialWeightKg = await _latestWeighInKg(container);
    if (!context.mounted) {
      return;
    }
    await subscription.read().showDialogForDay(
      context: context,
      selectedDay: today,
      day: today,
      initialWeightKg: initialWeightKg,
    );
  } finally {
    subscription.close();
  }
}

/// The last weigh-in of the weight chart, once it has loaded; `null` when
/// there is none. A load error leaves the field empty, because the chart
/// already shows that error.
Future<double?> _latestWeighInKg(ProviderContainer container) async {
  final scope = container.read(progressScopeControllerProvider);
  final loaded = Completer<double?>();
  // Watches the chart's weights until they load, also when the chart is not
  // built yet.
  final subscription = container.listen(progressWeightProvider(scope), (
    _,
    next,
  ) {
    if (!next.isLoading && !loaded.isCompleted) {
      loaded.complete(next.value?.trend.latestWeighInKg);
    }
  }, fireImmediately: true);
  try {
    return await loaded.future;
  } finally {
    subscription.close();
  }
}
