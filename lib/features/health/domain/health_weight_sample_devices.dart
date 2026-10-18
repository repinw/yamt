import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// A cloud copy of a Health weight sample and the devices whose Health store
/// holds it.
typedef DeviceHealthWeightSample = ({
  HealthWeightSample sample,
  Set<String> devices,
});

/// The cloud copies a change writes and the ids it deletes.
typedef HealthWeightSamplePlan = ({
  Map<String, DeviceHealthWeightSample> writes,
  Set<String> deletes,
});

/// The cloud copies one sync of [deviceId] writes and deletes.
///
/// [inHealth] is what the Health store of the device holds now, [stored]
/// what the cloud holds, both by measurement id. A sample of the device
/// gets the device. A copy from [mirrorSince] on that is no longer in its
/// Health store loses the device and every device outside [activeDevices]
/// (a reinstalled or retired install), and is deleted once no device holds
/// it. Older copies stay, because Health may not return them; nothing is
/// mirrored while [inHealth] has no sample from [mirrorSince] on.
HealthWeightSamplePlan healthWeightDeviceSync({
  required String deviceId,
  required Map<String, DeviceHealthWeightSample> stored,
  required Map<String, HealthWeightSample> inHealth,
  required DateTime mirrorSince,
  required Set<String> activeDevices,
}) {
  final writes = <String, DeviceHealthWeightSample>{};
  for (final MapEntry(key: id, value: sample) in inHealth.entries) {
    final copy = stored[id];
    if (copy == null) {
      writes[id] = (sample: sample, devices: {deviceId});
    } else if (!copy.devices.contains(deviceId)) {
      writes[id] = (sample: copy.sample, devices: {...copy.devices, deviceId});
    }
  }
  final deletes = <String>{};
  // An empty read is more likely a lost read access than a deletion of
  // every recent weighing, so it mirrors nothing.
  final readsRecentWeights = inHealth.values.any(
    (sample) => !sample.recordedAt.isBefore(mirrorSince),
  );
  for (final MapEntry(key: id, value: copy) in stored.entries) {
    if (!readsRecentWeights ||
        inHealth.containsKey(id) ||
        copy.sample.recordedAt.isBefore(mirrorSince)) {
      continue;
    }
    final devices = copy.devices.intersection(activeDevices)..remove(deviceId);
    if (devices.isEmpty) {
      deletes.add(id);
    } else if (devices.length != copy.devices.length) {
      writes[id] = (sample: copy.sample, devices: devices);
    }
  }
  return (writes: writes, deletes: deletes);
}

/// [copy] left out of every count, or counted again, on all devices. Throws
/// [StateError] without a copy.
DeviceHealthWeightSample healthWeightIgnoredCopy(
  DeviceHealthWeightSample? copy, {
  required bool ignored,
}) {
  if (copy == null) {
    throw StateError('The Health weight has no readable cloud copy.');
  }
  final sample = copy.sample;
  return (
    sample: HealthWeightSample(
      recordedAt: sample.recordedAt,
      weightKg: sample.weightKg,
      sourcePackageName: sample.sourcePackageName,
      isFromThisApp: sample.isFromThisApp,
      isIgnored: ignored,
    ),
    devices: copy.devices,
  );
}
