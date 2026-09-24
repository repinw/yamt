import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/data/'
    'firestore_manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';

part 'manual_health_weight_repository_provider.g.dart';

/// Manual health weight repository.
@riverpod
ManualHealthWeightRepository manualHealthWeightRepository(Ref ref) {
  return FirestoreManualHealthWeightRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    dataCipher: ref.watch(userDataCipherProvider),
  );
}
