import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/activity/application/'
    'diary_health_connect_action_provider.dart';
import 'package:yamt/features/activity/presentation/widgets/health_connect_metric_card/diary_health_connect_metric_shell.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

/// Compact Health Connect action card for blocked activity data.
class DiaryHealthConnectMetricCard extends ConsumerWidget {
  /// Creates a Health Connect card.
  const DiaryHealthConnectMetricCard({
    required this.accessState,
    super.key,
  });

  /// Current health data access state.
  final HealthDataAccessState accessState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionData = ref.watch(diaryHealthConnectActionProvider(accessState));
    final action = actionData.action;

    return DiaryHealthConnectMetricShell(
      accessState: actionData.accessState,
      hasConnectionError: actionData.hasConnectionError,
      isBusy: actionData.isBusy,
      onPressed: action == null ? null : () => unawaited(action()),
    );
  }
}
