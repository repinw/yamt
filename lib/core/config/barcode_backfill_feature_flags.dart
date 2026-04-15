import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'barcode_backfill_feature_flags.g.dart';

const _markerFlagKey = 'feature_inventory_barcode_markers';
const _queueFlagKey = 'feature_inventory_barcode_queue';

/// Remote-config-backed feature flags for barcode backfill experiments.
class BarcodeBackfillFeatureFlags {
  /// Creates barcode backfill feature flags.
  const BarcodeBackfillFeatureFlags({
    required this.showInventoryBarcodeMarkers,
    required this.enableQueueBackfill,
  });

  /// Whether inventory barcode marker UI should be visible.
  final bool showInventoryBarcodeMarkers;

  /// Whether queue-based barcode backfill is enabled.
  final bool enableQueueBackfill;

  /// Safe fallback values when remote config is unavailable.
  static const defaults = BarcodeBackfillFeatureFlags(
    showInventoryBarcodeMarkers: true,
    enableQueueBackfill: true,
  );
}

/// Resolves barcode backfill feature flags from Firebase Remote Config.
@riverpod
BarcodeBackfillFeatureFlags barcodeBackfillFeatureFlags(Ref ref) {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    return BarcodeBackfillFeatureFlags(
      showInventoryBarcodeMarkers: _readBool(
        remoteConfig: remoteConfig,
        key: _markerFlagKey,
        fallback:
            BarcodeBackfillFeatureFlags.defaults.showInventoryBarcodeMarkers,
      ),
      enableQueueBackfill: _readBool(
        remoteConfig: remoteConfig,
        key: _queueFlagKey,
        fallback: BarcodeBackfillFeatureFlags.defaults.enableQueueBackfill,
      ),
    );
  } on Object catch (error, stackTrace) {
    developer.log(
      'Falling back to default barcode feature flags.',
      name: 'BarcodeBackfillFeatureFlags',
      error: error,
      stackTrace: stackTrace,
    );
    return BarcodeBackfillFeatureFlags.defaults;
  }
}

bool _readBool({
  required FirebaseRemoteConfig remoteConfig,
  required String key,
  required bool fallback,
}) {
  final value = remoteConfig.getString(key).trim().toLowerCase();
  if (value == 'true') {
    return true;
  }
  if (value == 'false') {
    return false;
  }
  return fallback;
}
