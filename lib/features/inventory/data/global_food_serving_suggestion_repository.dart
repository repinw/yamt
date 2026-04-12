import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';

import 'firestore_global_food_serving_suggestion_repository.dart';
import 'global_food_serving_suggestion_repository_contract.dart';

export 'firestore_global_food_serving_suggestion_repository.dart';
export 'global_food_serving_suggestion_repository_contract.dart';

final globalFoodServingSuggestionRepositoryProvider =
    Provider<GlobalFoodServingSuggestionRepository>((ref) {
      final firestore = ref.watch(firebaseFirestoreProvider);
      final currentUserId = ref
          .watch(authStateChangesProvider)
          .asData
          ?.value
          ?.uid;
      if (firestore == null) {
        return const _UnavailableGlobalFoodServingSuggestionRepository();
      }
      return FirestoreGlobalFoodServingSuggestionRepository(
        firestore: firestore,
        currentUserId: currentUserId,
      );
    });

class _UnavailableGlobalFoodServingSuggestionRepository
    implements GlobalFoodServingSuggestionRepository {
  const _UnavailableGlobalFoodServingSuggestionRepository();

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async {
    return const GlobalFoodServingSuggestionSet.empty();
  }

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    String? globalFoodItemId,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
  }) async {}
}
