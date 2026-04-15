import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/health/data/'
    'firestore_manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';

part 'manual_health_weight_repository_provider.g.dart';

@riverpod
ManualHealthWeightRepository manualHealthWeightRepository(Ref ref) {
  String? currentUserId;
  try {
    currentUserId = ref.watch(authStateChangesProvider).asData?.value?.uid;
  } catch (_) {
    currentUserId = null;
  }
  return FirestoreManualHealthWeightRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    currentUserId: currentUserId,
  );
}
