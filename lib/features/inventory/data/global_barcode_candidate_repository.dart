import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

export 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository_contract.dart';

final globalBarcodeCandidateRepositoryProvider =
    Provider<GlobalBarcodeCandidateRepository>((ref) {
      final firestore = ref.watch(firebaseFirestoreProvider);
      final currentUserId = ref
          .watch(authStateChangesProvider)
          .asData
          ?.value
          ?.uid;
      if (firestore == null) {
        return const _UnavailableGlobalBarcodeCandidateRepository();
      }
      return FirestoreGlobalBarcodeCandidateRepository(
        firestore: firestore,
        currentUserId: currentUserId,
      );
    });

class _UnavailableGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  const _UnavailableGlobalBarcodeCandidateRepository();

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    return const <GlobalBarcodeCandidate>[];
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {}
}
