import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/inventory/data/sealed_household_document_writes.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';

part 'plan_reservation_repository.g.dart';

const _logName = 'PlanReservationRepository';
const _householdsCollection = 'households';
const _reservationsCollection = 'plan_reservations';

/// The plan reservations of the household members: one document per member
/// at `households/{hid}/plan_reservations/{uid}`, sealed with the household
/// key, so every member can read them.
class PlanReservationRepository with SealedHouseholdDocumentWrites {
  /// Creates the repository for the user [_uid] in [_household].
  const new({required this._household, required this._uid});

  /// The active household, or `null` without a household key.
  final HouseholdDataScope? _household;

  final String? _uid;

  /// The reservations of the other members, including members who left. A
  /// document that does not open or is malformed counts as none, so it does
  /// not hide the others.
  Stream<List<MemberPlanReservation>> watchOthers() {
    final household = _household;
    final uid = _uid;
    if (household == null || uid == null) {
      return Stream.value(const []);
    }
    final collection = householdCollection(household.householdId);
    return collection.reference.snapshots().asyncMap(
      (snapshot) async => [
        for (final document in snapshot.docs)
          if (document.id != uid) ...await _read(collection, document),
      ],
    );
  }

  /// Replaces the own reservations without waiting for the server; none
  /// deletes the document. Throws without a household key or a user, and
  /// when sealing fails.
  Future<void> saveOwn(List<PlanReservation> reservations) async {
    final household = _household;
    final uid = _uid;
    if (household == null || uid == null) {
      throw StateError('No household to share the plan reservations with.');
    }
    if (reservations.isEmpty) {
      await delete(householdId: household.householdId, id: uid);
      return;
    }
    final saved = await save(
      householdId: household.householdId,
      id: uid,
      data: planReservationsToJson(reservations),
    );
    if (!saved) {
      throw StateError('Sealing the plan reservations failed.');
    }
  }

  @override
  String get writeLogName => _logName;

  @override
  SealedCollection householdCollection(String householdId) {
    final household = _household!;
    return SealedCollection(
      household.firestore
          .collection(_householdsCollection)
          .doc(householdId)
          .collection(_reservationsCollection),
      cipher: household.cipher,
    );
  }

  Future<List<MemberPlanReservation>> _read(
    SealedCollection collection,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    try {
      final data = await collection.open(document);
      return [
        for (final reservation in planReservationsFromJson(data!))
          (uid: document.id, reservation: reservation),
      ];
    } on Object catch (error, stackTrace) {
      log(
        'Skipping the plan reservations of ${document.id}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }
}

/// The plan reservation repository of the signed-in user's household.
@riverpod
PlanReservationRepository planReservationRepository(Ref ref) =>
    PlanReservationRepository(
      household: ref.watch(householdDataScopeProvider),
      // Only the user: a token refresh must not start the sharing over.
      uid: ref.watch(
        authStateChangesProvider.select((user) => user.asData?.value?.uid),
      ),
    );
