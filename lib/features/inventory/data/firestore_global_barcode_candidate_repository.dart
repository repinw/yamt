import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

const String _repositoryLogName = 'FirestoreGlobalBarcodeCandidateRepository';
const String _usersCollection = 'users';
const String _candidatesCollection = 'global_barcode_candidates';
const String _votesCollection = 'global_barcode_candidate_votes';

class FirestoreGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  const FirestoreGlobalBarcodeCandidateRepository({
    required FirebaseFirestore firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    final normalizedBarcode = normalizeBarcode(barcode);
    if (normalizedBarcode.isEmpty) {
      return const <GlobalBarcodeCandidate>[];
    }

    final safeLimit = limit < 1 ? 1 : limit;
    try {
      final snapshot = await _candidateCollection()
          .where('barcode', isEqualTo: normalizedBarcode)
          .orderBy('unique_user_count', descending: true)
          .orderBy('selection_count', descending: true)
          .orderBy('completeness_score', descending: true)
          .orderBy('updated_at', descending: true)
          .limit(safeLimit)
          .get();
      return _decodeCandidates(snapshot.docs);
    } on FirebaseException catch (error, stackTrace) {
      log(
        'Barcode candidate index missing, falling back to client-side sort.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      try {
        final snapshot = await _candidateCollection()
            .where('barcode', isEqualTo: normalizedBarcode)
            .limit(safeLimit * 10)
            .get();
        final candidates = _decodeCandidates(snapshot.docs);
        candidates.sort(compareGlobalBarcodeCandidates);
        return candidates.take(safeLimit).toList(growable: false);
      } catch (fallbackError, fallbackStackTrace) {
        log(
          'Failed to read barcode candidates for $normalizedBarcode.',
          name: _repositoryLogName,
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );
        return const <GlobalBarcodeCandidate>[];
      }
    } catch (error, stackTrace) {
      log(
        'Failed to read barcode candidates for $normalizedBarcode.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <GlobalBarcodeCandidate>[];
    }
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    final currentUserId = _currentUserId?.trim();
    final normalizedBarcode = normalizeBarcode(barcode);
    final globalFoodItemId = globalFoodItem.id.trim();
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        normalizedBarcode.isEmpty ||
        globalFoodItemId.isEmpty) {
      return;
    }

    final candidateId = buildGlobalBarcodeCandidateId(
      barcode: normalizedBarcode,
      globalFoodItemId: globalFoodItemId,
    );
    final selectedAtText = selectedAt.toIso8601String();
    final candidateRef = _candidateCollection().doc(candidateId);
    final voteRef = _userVoteDocument(
      userId: currentUserId,
      documentId: candidateId,
    );

    await _firestore.runTransaction((transaction) async {
      final candidateSnapshot = await transaction.get(candidateRef);
      final voteSnapshot = await transaction.get(voteRef);
      final currentData = candidateSnapshot.data() ?? const <String, dynamic>{};
      final currentSelectionCount = _readPositiveInt(
        currentData['selection_count'],
      );
      final currentUniqueUserCount = _readPositiveInt(
        currentData['unique_user_count'],
      );
      final nextSelectionCount = (currentSelectionCount ?? 0) + 1;
      final nextUniqueUserCount =
          (currentUniqueUserCount ?? 0) + (voteSnapshot.exists ? 0 : 1);
      final createdAt = _readDateTime(currentData['created_at']) ?? selectedAt;
      final patchItem = globalFoodItem.copyWith(
        id: globalFoodItemId,
        barcode: normalizedBarcode,
      );
      final currentItemJson = _readMap(currentData['global_food_item']);
      final candidateItem = currentItemJson != null
          ? GlobalFoodItem.fromJson(
              currentItemJson,
            ).copyWith(id: globalFoodItemId)
          : patchItem;
      final candidate = GlobalBarcodeCandidate(
        id: candidateId,
        barcode: normalizedBarcode,
        globalFoodItemId: globalFoodItemId,
        selectionCount: nextSelectionCount,
        uniqueUserCount: nextUniqueUserCount,
        completenessScore:
            _readNonNegativeInt(currentData['completeness_score']) ??
            computeGlobalBarcodeCandidateCompletenessScore(candidateItem),
        globalFoodItem: candidateItem,
        createdAt: createdAt,
        updatedAt: selectedAt,
      );

      transaction.set(candidateRef, candidate.toJson());
      transaction.set(voteRef, <String, dynamic>{
        'barcode': normalizedBarcode,
        'global_food_item_id': globalFoodItemId,
        'candidate_id': candidateId,
        'created_at': voteSnapshot.data()?['created_at'] ?? selectedAtText,
        'updated_at': selectedAtText,
      });
    });
  }

  CollectionReference<Map<String, dynamic>> _candidateCollection() {
    return _firestore.collection(_candidatesCollection);
  }

  DocumentReference<Map<String, dynamic>> _userVoteDocument({
    required String userId,
    required String documentId,
  }) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_votesCollection)
        .doc(documentId);
  }

  List<GlobalBarcodeCandidate> _decodeCandidates(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final candidates = <GlobalBarcodeCandidate>[];
    for (var index = 0; index < documents.length; index++) {
      final json = Map<String, dynamic>.from(documents[index].data());
      if ((json['id'] as String?)?.trim().isEmpty ?? true) {
        json['id'] = documents[index].id;
      }
      try {
        candidates.add(GlobalBarcodeCandidate.fromJson(json));
      } catch (error, stackTrace) {
        log(
          'Skipping corrupted barcode candidate at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    candidates.sort(compareGlobalBarcodeCandidates);
    return candidates;
  }

  int? _readPositiveInt(Object? value) {
    if (value is int) {
      return value < 1 ? 1 : value;
    }
    if (value is num) {
      final normalized = value.toInt();
      return normalized < 1 ? 1 : normalized;
    }
    return null;
  }

  int? _readNonNegativeInt(Object? value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }
    if (value is num) {
      final normalized = value.toInt();
      return normalized < 0 ? 0 : normalized;
    }
    return null;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim());
  }

  Map<String, dynamic>? _readMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map<String, dynamic>(
      (key, item) => MapEntry<String, dynamic>(key.toString(), item),
    );
  }
}
