import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';

/// Runs an operation while keeping the Diary quick-eat action provider alive.
Future<T> withDiaryQuickEatActions<T>({
  required ProviderContainer container,
  required Future<T> Function() action,
}) async {
  final subscription = container.listen(
    diaryQuickEatInventoryActionsProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    return await action();
  } finally {
    subscription.close();
  }
}

/// Refreshes diary dashboard data after a quick-eat mutation.
void refreshDiaryAfterQuickEat(
  ProviderContainer container,
  DateTime loggedAt,
) {
  final day = normalizeLocalDay(loggedAt);
  unawaited(
    container
        .read(diaryDayDashboardControllerProvider(day).notifier)
        .refreshAfterMutation(),
  );
}

/// Shows a SnackBar for a Diary quick-eat result when the context is mounted.
void showDiaryQuickEatSnackBar(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  showDiaryQuickEatSnackBarWithMessenger(
    ScaffoldMessenger.of(context),
    message,
  );
}

/// Shows a SnackBar using an existing Scaffold messenger.
void showDiaryQuickEatSnackBarWithMessenger(
  ScaffoldMessengerState messenger,
  String message,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
