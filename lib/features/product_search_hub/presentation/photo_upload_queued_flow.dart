import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';

/// Logs a failure of the running photo upload [done] and calls [onQueued]:
/// the photo then waits on the device for a later try (#849).
void whenPhotoUploadQueued(Future<void>? done, VoidCallback onQueued) {
  unawaited(
    done?.then(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        log(
          'A photo upload failed; the photo waits on the device.',
          name: 'PhotoUpload',
          error: error,
          stackTrace: stackTrace,
        );
        onQueued();
      },
    ),
  );
}
