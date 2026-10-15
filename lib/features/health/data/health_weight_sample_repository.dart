import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

part 'health_weight_sample_repository.g.dart';

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
  );
}

/// Stores Health weight samples encrypted with the data key of the user.
///
/// Nothing is readable without the key: the document id is a keyed hash of
/// the minute and the weight, so equal measurements share a document.
class HealthWeightSampleRepository {
  /// Creates the repository for the signed-in user.
  new({required this._firestore, required this._dataCipher});

  final FirebaseFirestore? _firestore;
  final UserDataCipher? _dataCipher;

  /// Stores those of [samples] that are not stored yet.
  ///
  /// Samples at the same minute with the same weight to 0.01 kg are one
  /// measurement, whatever their source, so devices that read the same
  /// scale store it once. Throws [StateError] without a signed-in user.
  Future<void> addSamples(List<HealthWeightSample> samples) async {
    final collection = _collection();
    if (collection == null) {
      throw StateError('Health weight samples need a signed-in user.');
    }
    if (samples.isEmpty) {
      return;
    }
    final cipher = _dataCipher!.cipher;
    // From the cache, which the readers' watch keeps, so a weighing also
    // counts offline. A sample the cache misses is written again with the
    // same content.
    // shortcut: reads every stored id per sync; query by time once a
    // readable time field or a sync cursor exists.
    final stored = {
      for (final document in (await readQueryLocalFirst(collection)).docs)
        document.id,
    };
    final ids = await Future.wait(
      samples.map((sample) => _idOf(sample, cipher)),
    );
    final newSamples = <String, HealthWeightSample>{
      for (final (index, id) in ids.indexed)
        if (!stored.contains(id)) id: samples[index],
    };
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: newSamples.entries.toList(),
      maxChunkSize: _maxBatchWrites,
    )) {
      final batch = collection.firestore.batch();
      for (final MapEntry(key: id, value: sample) in chunk) {
        await _set(batch, collection.doc(id), sample, cipher);
      }
      commitBatchInBackground(
        batch,
        failureMessage: 'Failed to store Health weight samples.',
        logName: _logName,
      );
    }
  }

  /// Watches all stored samples, the local cache first. Each snapshot
  /// decrypts only the documents that changed.
  ///
  /// Without a signed-in user the list is empty. A failed read is delivered
  /// as an error.
  Stream<List<HealthWeightSample>> watchSamples() {
    final collection = _collection();
    if (collection == null) {
      return Stream.value(const <HealthWeightSample>[]);
    }
    final cipher = _dataCipher!.cipher;
    return Stream<List<HealthWeightSample>>.multi((controller) {
      // Decoded samples by document id; null marks a malformed document.
      final decoded = <String, HealthWeightSample?>{};
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
          for (final document in snapshot.docs) ?decoded[document.id],
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
  Future<List<HealthWeightSample>> readSamples() async {
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
    return List<HealthWeightSample>.unmodifiable(decoded.nonNulls);
  }

  /// Stores [weightKg] at [recordedAt] as the weight this app wrote to
  /// Health that day, replacing its earlier one of that day, as Health
  /// does. It does not wait for the server, so it also works offline.
  /// Throws [StateError] without a signed-in user.
  Future<void> saveAppWeight({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    final collection = _collection();
    if (collection == null) {
      throw StateError('Health weight samples need a signed-in user.');
    }
    final cipher = _dataCipher!.cipher;
    final sample = HealthWeightSample(
      recordedAt: recordedAt,
      weightKg: weightKg,
      isFromThisApp: true,
    );
    final reference = collection.doc(await _idOf(sample, cipher));
    // shortcut: decrypts every stored sample per save; keep the ids of the
    // app weights by day once saves get slow.
    final stored = await readQueryLocalFirst(collection);
    final decoded = await Future.wait(
      stored.docs.map((document) => _decodeOrNull(document, cipher)),
    );
    final batch = collection.firestore.batch();
    for (final (index, earlier) in decoded.indexed) {
      final document = stored.docs[index];
      if (earlier != null &&
          earlier.isFromThisApp &&
          document.id != reference.id &&
          isSameLocalDay(earlier.recordedAt, recordedAt)) {
        batch.delete(document.reference);
      }
    }
    await _set(batch, reference, sample, cipher);
    commitBatchInBackground(
      batch,
      failureMessage: 'Failed to store a Health weight sample.',
      logName: _logName,
    );
  }

  /// Removes the stored measurement that [sample] stands for. Throws
  /// [StateError] without a signed-in user.
  Future<void> deleteSample(HealthWeightSample sample) async {
    final collection = _collection();
    if (collection == null) {
      throw StateError('Health weight samples need a signed-in user.');
    }
    final id = await _idOf(sample, _dataCipher!.cipher);
    final batch = collection.firestore.batch()..delete(collection.doc(id));
    commitBatchInBackground(
      batch,
      failureMessage: 'Failed to delete a Health weight sample.',
      logName: _logName,
    );
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

  Future<void> _set(
    WriteBatch batch,
    DocumentReference<Map<String, dynamic>> reference,
    HealthWeightSample sample,
    PayloadCipher cipher,
  ) async {
    batch.set(reference, <String, Object?>{
      encryptedPayloadField: await cipher.encryptJson(
        sample.toJson(),
        aad: reference.path,
      ),
    });
  }

  /// The sample of [document], or `null`, logged, when it is malformed, as
  /// the diary entries do.
  Future<HealthWeightSample?> _decodeOrNull(
    DocumentSnapshot<Map<String, dynamic>> document,
    PayloadCipher cipher,
  ) async {
    try {
      final payload = document.data()?[encryptedPayloadField];
      if (payload is! String) {
        throw FormatException('Sample ${document.id} has no payload.');
      }
      return HealthWeightSample.fromJson(
        await cipher.decryptJson(payload, aad: document.reference.path),
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
