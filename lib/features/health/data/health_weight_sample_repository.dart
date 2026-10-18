import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/preferences/install_id.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/data/health_weight_sample_dto.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_weight_sample_devices.dart';

part 'health_weight_sample_repository.g.dart';

typedef _Session = ({
  CollectionReference<Map<String, dynamic>> collection,
  PayloadCipher cipher,
  String deviceId,
});

typedef _CopyChange = DeviceHealthWeightSample Function(
  DeviceHealthWeightSample? copy,
  String deviceId,
);

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
      samples.map((sample) => healthWeightSampleId(sample, cipher)),
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
              decoded[change.doc.id] = await decodeHealthWeightCopy(
                change.doc,
                cipher,
              );
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
    final stored = await _readStored(collection.get(), _dataCipher!.cipher);
    return List<HealthWeightSample>.unmodifiable([
      for (final copy in stored.values) copy.sample,
    ]);
  }

  /// Stores [weightKg] at [recordedAt] as a weighing this app wrote to the
  /// Health store of this device. It does not wait for the server, so it
  /// also works offline. Throws [StateError] without a signed-in user.
  Future<void> saveAppWeight({
    required DateTime recordedAt,
    required double weightKg,
  }) {
    final sample = HealthWeightSample(
      recordedAt: recordedAt,
      weightKg: weightKg,
      isFromThisApp: true,
    );
    return _rewrite(
      sample,
      (copy, deviceId) =>
          (sample: sample, devices: {...?copy?.devices, deviceId}),
    );
  }

  /// Leaves the copy of [sample] out of every count, or counts it again, on
  /// all devices. The copy keeps its devices. It does not wait for the
  /// server. Throws [StateError] without a signed-in user or a copy.
  Future<void> setIgnored(HealthWeightSample sample, {required bool ignored}) {
    return _rewrite(
      sample,
      (copy, _) => healthWeightIgnoredCopy(copy, ignored: ignored),
    );
  }

  /// Deletes the copy of [sample], which the user deleted in this app.
  Future<void> deleteSample(HealthWeightSample sample) async {
    final (:collection, :cipher, deviceId: _) = await _session();
    await _commit(collection, cipher, (
      writes: const {},
      deletes: {await healthWeightSampleId(sample, cipher)},
    ));
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

  /// Writes the copy of [sample] that [change] makes of the stored one.
  Future<void> _rewrite(HealthWeightSample sample, _CopyChange change) async {
    final (:collection, :cipher, :deviceId) = await _session();
    final id = await healthWeightSampleId(sample, cipher);
    // From the cache, so a change never waits for the network; the readers'
    // watch keeps it current.
    final stored = await _readStored(
      readQueryLocalFirst(
        collection.where(FieldPath.documentId, isEqualTo: id),
      ),
      cipher,
    );
    await _commit(collection, cipher, (
      writes: {id: change(stored[id], deviceId)},
      deletes: const <String>{},
    ));
  }

  // shortcut: decrypts every stored copy; keep an index once it gets slow.
  Future<Map<String, DeviceHealthWeightSample>> _readStored(
    Future<QuerySnapshot<Map<String, dynamic>>> read,
    PayloadCipher cipher,
  ) async {
    final documents = (await read).docs;
    final decoded = await Future.wait(
      documents.map((document) => decodeHealthWeightCopy(document, cipher)),
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
          batch.set(
            reference,
            await encodeHealthWeightCopy(copy, cipher, reference.path),
          );
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
}
