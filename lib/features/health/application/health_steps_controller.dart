import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

part 'health_steps_controller.g.dart';

/// Device preference key of the steps choice.
const healthStepsPreferenceKey = 'health_steps_v1';

/// How turning the steps on ended.
enum HealthStepsEnableResult {
  /// The steps are on.
  enabled,

  /// Health is not connected, or the user declined the steps.
  denied,

  /// The device has no Health.
  unsupported,
}

/// Whether the app shows the user's steps, saved on the device. Off until the
/// user turns it on; turning it on connects Health when needed and asks for
/// the steps permission. Disconnecting Health turns it off.
@riverpod
class HealthStepsController extends _$HealthStepsController {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getIntSync(healthStepsPreferenceKey) ==
      1;

  /// Connects Health when it is not ready, asks for the steps, and turns
  /// steps on once both are granted. Returns how that ended.
  Future<HealthStepsEnableResult> enable() async {
    // The user may leave the page while a dialog is open: this controller
    // stays for the whole action, and with it the connection controller.
    final link = ref.keepAlive();
    final subscription = ref.listen(
      healthConnectionControllerProvider,
      (_, _) {},
    );
    try {
      // A fresh status, since the user may come back from the store or the
      // settings.
      var status = await ref.read(healthConnectionServiceProvider).loadStatus();
      if (status.accessState != HealthDataAccessState.ready) {
        final connection = ref.read(
          healthConnectionControllerProvider.notifier,
        );
        status = status.needsInstall
            ? await connection.installHealthConnect()
            : await connection.connect();
      }
      if (status.accessState == HealthDataAccessState.unsupported) {
        return HealthStepsEnableResult.unsupported;
      }
      if (status.accessState != HealthDataAccessState.ready ||
          !await ref.read(healthStepsServiceProvider).requestAccess()) {
        return HealthStepsEnableResult.denied;
      }
      await ref
          .read(appPreferencesProvider)
          .setInt(healthStepsPreferenceKey, 1);
      state = true;
      return HealthStepsEnableResult.enabled;
    } finally {
      subscription.close();
      link.close();
    }
  }

  /// Turns steps off. The platform permission stays; the user revokes it in
  /// Health.
  Future<void> disable() async {
    await ref.read(appPreferencesProvider).remove(healthStepsPreferenceKey);
    if (ref.mounted) {
      state = false;
    }
  }
}
