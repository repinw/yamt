import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
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
    // From the server only: no screen watches the samples, so the cache can
    // miss those of other devices. Offline, the read fails and the sync
    // waits for the next run.
    // shortcut: reads every stored id per sync; query by time once a
    // readable time field or a sync cursor exists.
    final stored = {
      for (final document in (await collection.get(
        const GetOptions(source: Source.server),
      )).docs)
        document.id,
    };
    final ids = await Future.wait(
      samples.map((sample) => cipher.keyedId(_measurementKey(sample))),
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
        final reference = collection.doc(id);
        batch.set(reference, <String, Object?>{
          encryptedPayloadField: await cipher.encryptJson(
            _toJson(sample),
            aad: reference.path,
          ),
        });
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

/// The measurement a sample stands for: its minute in UTC and its weight to
/// 0.01 kg.
String _measurementKey(HealthWeightSample sample) {
  final minute = sample.recordedAt.toUtc().toIso8601String().substring(0, 16);
  return 'health-weight-sample:$minute:${sample.weightKg.toStringAsFixed(2)}';
}

Map<String, dynamic> _toJson(HealthWeightSample sample) {
  return <String, dynamic>{
    'recordedAt': sample.recordedAt.toUtc(),
    'weightKg': sample.weightKg,
    'source': ?sample.sourcePackageName,
  };
}
