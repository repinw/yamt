import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_member.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  HouseholdMemberRepository repositoryFor(String uid) {
    return HouseholdMemberRepository(
      firestore: firestore,
      keys: HouseholdKeyRepository(
        firestore: firestore,
        storage: const FlutterSecureStorage(),
      ),
      currentUserId: uid,
    );
  }

  Future<void> addMember(String uid, String role, DateTime joinedAt) {
    return firestore.doc('households/h1/members/$uid').set(<String, dynamic>{
      'uid': uid,
      'role': role,
      'joined_at': Timestamp.fromDate(joinedAt),
    });
  }

  Future<String?> roleOf(String uid) async {
    return (await firestore.doc('households/h1/members/$uid').get())
            .data()?['role']
        as String?;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    await addMember('late', 'member', DateTime(2026, 3));
    await addMember('admin', 'admin', DateTime(2026, 4));
    await addMember('early', 'member', DateTime(2026, 2));
    await firestore.doc('users/admin').set(<String, dynamic>{
      'uid': 'admin',
      'displayName': 'Alex',
      'email': 'alex@example.com',
    });
    await firestore.doc('users/early').set(<String, dynamic>{
      'uid': 'early',
      'email': 'early@example.com',
    });
  });

  test('watchMembers lists the admin first, then by join date, with the '
      'names from the profiles', () async {
    final members = await repositoryFor('admin').watchMembers('h1').first;

    expect(members.map((member) => member.uid), <String>[
      'admin',
      'early',
      'late',
    ]);
    expect(members.first.displayName, 'Alex');
    expect(members.first.email, 'alex@example.com');
    expect(members[1].displayName, isNull);
    expect(members[1].email, 'early@example.com');
    expect(members.last.email, isNull);
  });

  test('loadHasOtherMembers ignores the current user', () async {
    await firestore.doc('households/h2/members/solo').set(<String, dynamic>{
      'uid': 'solo',
      'role': 'admin',
      'joined_at': Timestamp.fromDate(DateTime(2026)),
    });

    expect(await repositoryFor('admin').loadHasOtherMembers('h1'), isTrue);
    expect(await repositoryFor('solo').loadHasOtherMembers('h2'), isFalse);
  });

  test('watchMembershipEnded reports a removal', () async {
    final ended = Completer<void>();
    final subscription = repositoryFor('late')
        .watchMembershipEnded('h1')
        .listen(ended.complete);
    addTearDown(subscription.cancel);

    await firestore.doc('households/h1/members/late').delete();

    await ended.future.timeout(const Duration(seconds: 1));
  });

  test('the admin removes a member with the key entry and the restore '
      'request', () async {
    await firestore.doc('households/h1/keys/late').set(<String, dynamic>{
      'wrapped_key': 'k',
    });
    await firestore
        .doc('households/h1/key_restores/late')
        .set(<String, dynamic>{});

    await repositoryFor('admin').removeMember('h1', 'late');

    for (final path in <String>[
      'households/h1/members/late',
      'households/h1/keys/late',
      'households/h1/key_restores/late',
    ]) {
      expect((await firestore.doc(path).get()).exists, isFalse, reason: path);
    }
  });

  test('only the admin removes members, and only other members', () async {
    await expectLater(
      repositoryFor('early').removeMember('h1', 'late'),
      throwsA(isA<HouseholdAdminRequiredException>()),
    );
    await expectLater(
      repositoryFor('admin').removeMember('h1', 'admin'),
      throwsA(isA<HouseholdMemberNotFoundException>()),
    );
    await expectLater(
      repositoryFor('admin').removeMember('h1', 'stranger'),
      throwsA(isA<HouseholdMemberNotFoundException>()),
    );
  });

  test('makeAdmin hands the lead on and keeps the admin as a member', () async {
    await repositoryFor('admin').makeAdmin('h1', 'late');

    expect(await roleOf('late'), HouseholdRole.admin.name);
    expect(await roleOf('admin'), HouseholdRole.member.name);
    await expectLater(
      repositoryFor('admin').makeAdmin('h1', 'early'),
      throwsA(isA<HouseholdAdminRequiredException>()),
    );
  });
}
