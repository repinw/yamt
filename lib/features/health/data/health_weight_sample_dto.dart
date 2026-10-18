import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_weight_sample_devices.dart';

/// The document id of the measurement [sample] stands for: a keyed hash of
/// its minute in UTC and its weight to 0.01 kg, so equal measurements share
/// a document and nothing is readable without the key.
Future<String> healthWeightSampleId(
  HealthWeightSample sample,
  PayloadCipher cipher,
) {
  final minute = sample.recordedAt.toUtc().toIso8601String().substring(0, 16);
  return cipher.keyedId(
    'health-weight-sample:$minute:${sample.weightKg.toStringAsFixed(2)}',
  );
}

/// The stored document of [copy] at [path]: the sample and its devices,
/// encrypted.
Future<Map<String, Object?>> encodeHealthWeightCopy(
  DeviceHealthWeightSample copy,
  PayloadCipher cipher,
  String path,
) async {
  return <String, Object?>{
    encryptedPayloadField: await cipher.encryptJson({
      ...copy.sample.toJson(),
      'devices': copy.devices.toList(),
    }, aad: path),
  };
}

/// The copy stored in [document], or `null`, logged, when it is malformed,
/// as the diary entries do.
Future<DeviceHealthWeightSample?> decodeHealthWeightCopy(
  DocumentSnapshot<Map<String, dynamic>> document,
  PayloadCipher cipher,
) async {
  try {
    final payload = document.data()?[encryptedPayloadField];
    if (payload is! String) {
      throw FormatException('Sample ${document.id} has no payload.');
    }
    final json = await cipher.decryptJson(
      payload,
      aad: document.reference.path,
    );
    return (
      sample: HealthWeightSample.fromJson(json),
      // Strict: no released app (v3.7.0 and older) wrote this
      // collection, so every copy has its devices and fromThisApp.
      devices: {...(json['devices'] as List<dynamic>).cast<String>()},
    );
  } on Object catch (error, stackTrace) {
    log(
      'Skipping malformed Health weight sample ${document.id}.',
      name: 'HealthWeightSampleDto',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
