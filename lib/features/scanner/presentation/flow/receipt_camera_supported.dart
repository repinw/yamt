import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receipt_camera_supported.g.dart';

/// Returns whether receipt camera capture is supported on current platform.
@riverpod
bool receiptCameraSupported(Ref ref) {
  if (kIsWeb) {
    return false;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => true,
    TargetPlatform.iOS => true,
    TargetPlatform.macOS => false,
    TargetPlatform.windows => false,
    TargetPlatform.linux => false,
    TargetPlatform.fuchsia => false,
  };
}
