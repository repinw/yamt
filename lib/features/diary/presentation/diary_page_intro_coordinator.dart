import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_intro_data.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';

/// Resolves the health permission callback action for diary intro dialogs.
DiaryIntroHealthAction? resolveDiaryIntroHealthAction(
  WidgetRef ref,
  HealthConnectionStatus? status,
) {
  if (status == null) {
    return null;
  }
  final hasConnectionError = status.errorMessage != null;
  final needsAppPermissionSettings =
      status.errorMessage == healthActivityRecognitionPermissionErrorMessage;
  final controller = ref.read(healthConnectionControllerProvider.notifier);
  final action = switch (status.accessState) {
    HealthDataAccessState.permissionRequired ||
    HealthDataAccessState.historyRequired =>
      hasConnectionError
          ? needsAppPermissionSettings
                ? controller.openAppPermissionSettings
                : controller.openHealthPermissionSettings
          : controller.connect,
    HealthDataAccessState.installRequired => controller.installHealthConnect,
    HealthDataAccessState.ready || HealthDataAccessState.unsupported => null,
  };
  if (action == null) {
    return null;
  }
  return DiaryIntroHealthAction(
    accessState: status.accessState,
    hasConnectionError: hasConnectionError,
    onPressed: () => unawaited(action()),
  );
}

/// Displays the diary intro dialog and marks it as seen upon completion.
Future<void> runDiaryIntroFlow({
  required BuildContext context,
  required WidgetRef ref,
  required DiaryIntroData introData,
  required HealthConnectionStatus? healthStatus,
}) async {
  final healthAction = resolveDiaryIntroHealthAction(ref, healthStatus);
  final completed = await showDiaryIntroDialog(
    context: context,
    data: introData,
    healthAction: healthAction,
  );
  if (!context.mounted || completed != true) {
    return;
  }
  final preferences = ref.read(appPreferencesProvider);
  await DiaryIntroPreferences.markSeen(preferences);
}
