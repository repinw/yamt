import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/domain/household_member.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdKeyRepository keys;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    keys = HouseholdKeyRepository(
      firestore: firestore,
      storage: const FlutterSecureStorage(),
    );
    for (final (uid, role, month) in <(String, String, int)>[
      ('member-2', 'member', 3),
      ('admin', 'admin', 1),
      ('member-1', 'member', 2),
    ]) {
      await firestore.doc('households/h1/members/$uid').set(<String, dynamic>{
        'uid': uid,
        'role': role,
        'joined_at': Timestamp.fromDate(DateTime(2026, month)),
      });
    }
  });

  Future<ProviderContainer> createContainer({String? householdId}) async {
    final container = ProviderContainer(
      overrides: [
        activeHouseholdIdProvider.overrideWithValue(householdId),
        householdKeyRepositoryProvider.overrideWithValue(keys),
        householdMemberRepositoryProvider.overrideWithValue(
          HouseholdMemberRepository(
            firestore: firestore,
            keys: keys,
            currentUserId: 'member-1',
          ),
        ),
        userDataCipherProvider.overrideWithValue((
          uid: 'member-1',
          cipher: PayloadCipher(await PayloadCipher.newDataKey()),
        )),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<T> firstValue<T>(
    ProviderContainer container,
    ProviderListenable<AsyncValue<T>> provider,
  ) {
    final value = Completer<T>();
    final subscription = container.listen(provider, (_, next) {
      if (next.hasValue && !value.isCompleted) {
        value.complete(next.value as T);
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);
    return value.future.timeout(const Duration(seconds: 5));
  }

  test('householdMembersProvider lists the members of the active household, '
      'the admin first', () async {
    final container = await createContainer(householdId: 'h1');

    final members = await firstValue(container, householdMembersProvider);

    expect(members.map((member) => member.uid), <String>[
      'admin',
      'member-1',
      'member-2',
    ]);
  });

  test('householdMembersProvider is empty without a household', () async {
    final container = await createContainer();

    expect(await firstValue(container, householdMembersProvider), isEmpty);
  });

  test('householdKeyRestoreRequestsProvider lists the other members who wait '
      'for the key', () async {
    for (final uid in <String>['member-1', 'member-2']) {
      await keys.requestKeyRestore(householdId: 'h1', memberUid: uid);
    }
    final container = await createContainer(householdId: 'h1');

    final waiting = await firstValue<List<HouseholdMember>>(
      container,
      householdKeyRestoreRequestsProvider,
    );

    expect(waiting.map((member) => member.uid), <String>['member-2']);
  });
}
