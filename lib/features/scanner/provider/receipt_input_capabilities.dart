import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receipt_input_capabilities.g.dart';

/// Receipt camera supported.
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
