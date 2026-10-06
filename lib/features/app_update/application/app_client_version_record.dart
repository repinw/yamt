import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/app_update/data/app_client_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

part 'app_client_version_record.g.dart';

/// Saves the app version of this device whenever a user signs in or the app
/// starts. `lib/app.dart` keeps it alive for the app's lifetime. A failed
/// write only logs: the next start tries again.
@riverpod
Future<void> appClientVersionRecord(Ref ref) async {
  final uid = await ref.watch(
    authStateChangesProvider.selectAsync((user) => user?.uid),
  );
  if (uid == null || !ref.mounted) {
    return;
  }
  final appVersion = await ref.watch(appVersionProvider.future);
  if (!ref.mounted) {
    return;
  }
  try {
    await ref
        .read(appClientRepositoryProvider)
        .saveClientVersion(
          uid: uid,
          appVersion: appVersion,
          now: ref.read(clockProvider)(),
        );
  } on Object catch (error, stackTrace) {
    log(
      'Saving the app version of this device failed.',
      name: 'AppUpdate',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
