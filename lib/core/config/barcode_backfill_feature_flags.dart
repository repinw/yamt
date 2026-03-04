// ignore_for_file: experimental_member_use

import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'barcode_backfill_feature_flags.g.dart';

const _markerFlagKey = 'feature_inventory_barcode_markers';
const _eatBridgeFlagKey = 'feature_inventory_eat_barcode_bridge';
const _queueFlagKey = 'feature_inventory_barcode_queue';

class BarcodeBackfillFeatureFlags {
  const BarcodeBackfillFeatureFlags({
    required this.showInventoryBarcodeMarkers,
    required this.enableEatBridge,
    required this.enableQueueBackfill,
  });

  final bool showInventoryBarcodeMarkers;
  final bool enableEatBridge;
  final bool enableQueueBackfill;

  static const defaults = BarcodeBackfillFeatureFlags(
    showInventoryBarcodeMarkers: true,
    enableEatBridge: true,
    enableQueueBackfill: true,
  );
}

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
      enableEatBridge: _readBool(
        remoteConfig: remoteConfig,
        key: _eatBridgeFlagKey,
        fallback: BarcodeBackfillFeatureFlags.defaults.enableEatBridge,
      ),
      enableQueueBackfill: _readBool(
        remoteConfig: remoteConfig,
        key: _queueFlagKey,
        fallback: BarcodeBackfillFeatureFlags.defaults.enableQueueBackfill,
      ),
    );
  } catch (error, stackTrace) {
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
