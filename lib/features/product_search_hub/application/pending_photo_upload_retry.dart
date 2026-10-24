import 'dart:developer' show log;

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/network_connectivity.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/product_search_hub/data/photo_upload_repository.dart';

part 'pending_photo_upload_retry.g.dart';

/// Uploads the photos that a failed or interrupted upload left on the
/// device, whenever the app starts or comes back to the foreground, a user
/// signs in, or the device comes back online. Signing out deletes them. `lib/app.dart` keeps it alive for
/// the app's lifetime. A failure only logs: the next run tries again.
@riverpod
Future<void> pendingPhotoUploadRetry(Ref ref) async {
  // Wi-Fi without internet never counts as offline, so the device going
  // online is not the only moment to try again.
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(lifecycle.dispose);
  final uid = await ref.watch(
    authStateChangesProvider.selectAsync((user) => user?.uid),
  );
  if (!ref.mounted) return;
  final uploads = ref.watch(photoUploadRepositoryProvider);
  try {
    if (uid == null) {
      await uploads.deletePendingPhotos();
      return;
    }
    final offline = await ref.watch(deviceOfflineProvider.future);
    if (offline || !ref.mounted) return;
    await uploads.uploadPendingPhotos(now: ref.watch(clockProvider)());
  } on Object catch (error, stackTrace) {
    log(
      'Retrying the pending photo uploads failed.',
      name: 'PendingPhotoUploadRetry',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
