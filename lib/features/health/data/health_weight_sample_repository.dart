import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/preferences/install_id.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_weight_sample_devices.dart';

part 'health_weight_sample_repository.g.dart';

typedef _Session = ({
  CollectionReference<Map<String, dynamic>> collection,
  PayloadCipher cipher,
  String deviceId,
});

const _usersCollection = 'users';
const _samplesCollection = 'health_weight_samples';
const _logName = 'HealthWeightSampleRepository';
// Firestore allows 500 writes per batch.
const _maxBatchWrites = 450;

/// The Health weight samples of the user's devices, in the cloud.
@riverpod
HealthWeightSampleRepository healthWeightSampleRepository(Ref ref) {
  return HealthWeightSampleRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    dataCipher: ref.watch(userDataCipherProvider),
    preferences: ref.watch(appPreferencesProvider),
  );
}

/// Stores Health weight samples encrypted with the data key of the user.
///
/// Nothing is readable without the key: the document id is a keyed hash of
/// the minute and the weight, so equal measurements share a document. Each
/// copy lists the devices (install ids) whose Health store holds it, so a
/// deletion in one Health store removes the copy only once no device holds
/// it.
class HealthWeightSampleRepository {
  /// Creates the repository for the signed-in user.
  new({
    required this._firestore,
    required this._dataCipher,
    required this._preferences,
  });

  final FirebaseFirestore? _firestore;
  final UserDataCipher? _dataCipher;
  final AppPreferences _preferences;

  /// Mirrors the Health store of this device: [loadHealth] returns all it
  /// holds from [mirrorSince] on, or more. It runs after the stored copies
  /// are read, so a weight saved meanwhile is never taken as deleted. A
  /// copy from [mirrorSince] on that this device no longer holds loses it
  /// and the devices outside [activeDevices], and is deleted once no device
  /// holds it. Throws [StateError] without a signed-in user.
  Future<void> syncDevice({
    required Future<List<HealthWeightSample>> Function() loadHealth,
    required DateTime mirrorSince,
    required Set<String> activeDevices,
  }) async {
    final (:collection, :cipher, :deviceId) = await _session();
    // From the server, so a fresh cache does not drop the devices of a
    // copy; from the cache offline, so a weighing also counts there.
    final stored = await _readStored(collection.get(), cipher);
    final samples = await loadHealth();
    final ids = await Future.wait(
      samples.map((sample) => _idOf(sample, cipher)),
    );
    final plan = healthWeightDeviceSync(
      deviceId: deviceId,
      stored: stored,
      inHealth: {for (final (index, id) in ids.indexed) id: samples[index]},
      mirrorSince: mirrorSince,
      activeDevices: activeDevices,
    );
    await _commit(collection, cipher, plan);
  }

  /// Watches all stored samples, the local cache first, decrypting only the
  /// changed documents. Empty without a user; a failed read is an error.
  Stream<List<HealthWeightSample>> watchSamples() {
    final collection = _collection();
    if (collection == null) {
      return Stream.value(const <HealthWeightSample>[]);
    }
    final cipher = _dataCipher!.cipher;
    return Stream<List<HealthWeightSample>>.multi((controller) {
      // Decoded samples by document id; null marks a malformed document.
      final decoded = <String, DeviceHealthWeightSample?>{};
      Future<List<HealthWeightSample>> decodeChanges(
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) async {
        await Future.wait(
          snapshot.docChanges.map((change) async {
            if (change.type == DocumentChangeType.removed) {
              decoded.remove(change.doc.id);
            } else {
              decoded[change.doc.id] = await _decodeOrNull(change.doc, cipher);
            }
          }),
        );
        return List<HealthWeightSample>.unmodifiable([
          for (final document in snapshot.docs) ?decoded[document.id]?.sample,
        ]);
      }

      final subscription = collection
          .snapshots()
          .asyncMap(decodeChanges)
          .listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
      controller.onCancel = subscription.cancel;
    });
  }

  /// Reads all stored samples, from the server when online, so a fresh
  /// cache does not hide the samples of other devices. Without a signed-in
  /// user the list is empty.
  Future<List<HealthWeightSample>> loadSamples() async {
    final collection = _collection();
    if (collection == null) {
      return const <HealthWeightSample>[];
    }
    final cipher = _dataCipher!.cipher;
    final decoded = await Future.wait(
      (await collection.get()).docs.map(
        (document) => _decodeOrNull(document, cipher),
      ),
    );
    return List<HealthWeightSample>.unmodifiable([
      for (final copy in decoded.nonNulls) copy.sample,
    ]);
  }

  /// Stores [weightKg] at [recordedAt] as the weight this app wrote to the
  /// Health store of this device that day, replacing its earlier one of
  /// that day, as Health does. It does not wait for the server, so it also
  /// works offline. Throws [StateError] without a signed-in user.
  Future<void> saveAppWeight({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    final (:collection, :cipher, :deviceId) = await _session();
    final sample = HealthWeightSample(
      recordedAt: recordedAt,
      weightKg: weightKg,
      isFromThisApp: true,
    );
    final id = await _idOf(sample, cipher);
    final plan = healthWeightAppWeightSave(
      deviceId: deviceId,
      // From the cache, so a save never waits for the network; the
      // readers' watch keeps it current.
      stored: await _readStored(readQueryLocalFirst(collection), cipher),
      id: id,
      sample: sample,
    );
    await _commit(collection, cipher, plan);
  }

  /// Deletes the copy of [sample], which the user deleted in this app.
  Future<void> deleteSample(HealthWeightSample sample) async {
    final (:collection, :cipher, deviceId: _) = await _session();
    final batch = collection.firestore.batch()
      ..delete(collection.doc(await _idOf(sample, cipher)));
    commitBatchInBackground(
      batch,
      failureMessage: 'Failed to delete a Health weight sample.',
      logName: _logName,
    );
  }

  Future<_Session> _session() async {
    final collection = _collection();
    if (collection == null) {
      throw StateError('Health weight samples need a signed-in user.');
    }
    return (
      collection: collection,
      cipher: _dataCipher!.cipher,
      deviceId: await readInstallId(_preferences),
    );
  }

  // shortcut: decrypts every stored copy; keep an index once it gets slow.
  Future<Map<String, DeviceHealthWeightSample>> _readStored(
    Future<QuerySnapshot<Map<String, dynamic>>> read,
    PayloadCipher cipher,
  ) async {
    final documents = (await read).docs;
    final decoded = await Future.wait(
      documents.map((document) => _decodeOrNull(document, cipher)),
    );
    return {
      for (final (index, copy) in decoded.indexed) documents[index].id: ?copy,
    };
  }

  /// Writes and deletes the copies of [plan] without waiting for the server.
  Future<void> _commit(
    CollectionReference<Map<String, dynamic>> collection,
    PayloadCipher cipher,
    HealthWeightSamplePlan plan,
  ) async {
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: [
        ...plan.writes.entries.map((write) => (write.key, write.value)),
        ...plan.deletes.map((id) => (id, null)),
      ],
      maxChunkSize: _maxBatchWrites,
    )) {
      final batch = collection.firestore.batch();
      for (final (id, copy) in chunk) {
        final reference = collection.doc(id);
        if (copy == null) {
          batch.delete(reference);
        } else {
          batch.set(reference, <String, Object?>{
            encryptedPayloadField: await cipher.encryptJson({
              ...copy.sample.toJson(),
              'devices': copy.devices.toList(),
            }, aad: reference.path),
          });
        }
      }
      commitBatchInBackground(
        batch,
        failureMessage: 'Failed to store Health weight samples.',
        logName: _logName,
      );
    }
  }

  CollectionReference<Map<String, dynamic>>? _collection() {
    final firestore = _firestore;
    final userId = _dataCipher?.uid;
    if (firestore == null || userId == null) {
      return null;
    }
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_samplesCollection);
  }

  /// The id of the measurement [sample] stands for: its minute in UTC and
  /// its weight to 0.01 kg.
  Future<String> _idOf(HealthWeightSample sample, PayloadCipher cipher) {
    final minute = sample.recordedAt.toUtc().toIso8601String().substring(0, 16);
    return cipher.keyedId(
      'health-weight-sample:$minute:${sample.weightKg.toStringAsFixed(2)}',
    );
  }

  /// The sample of [document], or `null`, logged, when it is malformed, as
  /// the diary entries do.
  Future<DeviceHealthWeightSample?> _decodeOrNull(
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
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
