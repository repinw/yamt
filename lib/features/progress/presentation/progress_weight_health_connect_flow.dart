import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Takes the next step to Health access from the weight list, and reports a
/// refused request.
Future<void> connectProgressWeightHealth(
  BuildContext context,
  WidgetRef ref,
) async {
  // A tap while a request runs would start a second one.
  final current = ref.read(healthConnectionControllerProvider);
  if (current.isLoading) return;
  // Installing and the permission settings come back before the user is
  // done there, so only a refused request counts as failed.
  final isRequest =
      current.value?.accessState != HealthDataAccessState.installRequired &&
      current.value?.errorMessage == null;
  final status = await ref
      .read(healthConnectionControllerProvider.notifier)
      .requestAccess();
  if (!isRequest ||
      !context.mounted ||
      status.accessState == HealthDataAccessState.ready) {
    return;
  }
  ScaffoldMessenger.of(context).showAppSnackBar(
    AppLocalizations.of(context)!.settingsHealthConnectFailed,
    tone: AppSnackBarTone.error,
  );
}
