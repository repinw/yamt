import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/domain/household_member.dart';

HouseholdMember _member(String uid, DateTime joinedAt, {bool admin = false}) {
  return HouseholdMember(
    uid: uid,
    role: admin ? HouseholdRole.admin : HouseholdRole.member,
    joinedAt: joinedAt,
  );
}

void main() {
  test('fromJson reads the member document', () {
    final member = HouseholdMember.fromJson(<String, dynamic>{
      'uid': 'member-1',
      'role': 'admin',
      'joined_at': DateTime(2026, 9, 28),
      'invite_code': 'AbCdEfGhIjKlMnOpQrSt',
    });

    expect(member.uid, 'member-1');
    expect(member.isAdmin, isTrue);
    expect(member.joinedAt, DateTime(2026, 9, 28));
    expect(member.displayName, isNull);
  });

  test('fromJson rejects an unknown role', () {
    expect(
      () => HouseholdMember.fromJson(<String, dynamic>{
        'uid': 'member-1',
        'role': 'owner',
        'joined_at': DateTime(2026, 9, 28),
      }),
      throwsArgumentError,
    );
  });

  test('proposeSuccessor picks the member who joined first', () {
    final members = <HouseholdMember>[
      _member('admin', DateTime(2026), admin: true),
      _member('late', DateTime(2026, 3)),
      _member('early', DateTime(2026, 2)),
    ];

    expect(proposeSuccessor(members, 'admin')?.uid, 'early');
    expect(proposeSuccessor(members, 'early')?.uid, 'admin');
  });

  test('proposeSuccessor finds nobody when the user is alone', () {
    expect(
      proposeSuccessor(<HouseholdMember>[
        _member('admin', DateTime(2026), admin: true),
      ], 'admin'),
      isNull,
    );
  });
}
