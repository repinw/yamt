import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_invite_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_invite_code_controller.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/memory_app_preferences.dart';

class _FakeInviteRepository extends Fake implements HouseholdInviteRepository {
  final joins = <(String, String, String)>[];
  Exception? error;

  @override
  Future<void> joinHousehold(
    HouseholdInvite invite, {
    required String activeHouseholdId,
    required String ownHouseholdId,
  }) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    joins.add((invite.code, activeHouseholdId, ownHouseholdId));
  }
}

class _FakeHouseholdRepository extends Fake implements HouseholdRepository {
  final leaves = <(String, String, String?)>[];

  @override
  Future<void> leaveHousehold({
    required String householdId,
    required String ownHouseholdId,
    String? successorUid,
  }) async {
    leaves.add((householdId, ownHouseholdId, successorUid));
  }
}

class _FakeMemberRepository extends Fake implements HouseholdMemberRepository {
  final calls = <String>[];

  @override
  Future<void> removeMember(String householdId, String memberUid) async {
    calls.add('remove $householdId $memberUid');
  }

  @override
  Future<void> makeAdmin(String householdId, String memberUid) async {
    calls.add('admin $householdId $memberUid');
  }
}

class _TestInviteCodeController extends HouseholdInviteCodeController {
  @override
  AsyncValue<HouseholdInvite?> build() {
    return AsyncData<HouseholdInvite?>(_invite('ZyXwVuTsRqPoNmLkJiHg'));
  }
}

HouseholdInvite _invite(String code) {
  return HouseholdInvite(code: code, secret: RecoveryKey.generate());
}

void main() {
  late _FakeInviteRepository invites;
  late _FakeHouseholdRepository households;
  late _FakeMemberRepository members;

  setUp(() {
    invites = _FakeInviteRepository();
    households = _FakeHouseholdRepository();
    members = _FakeMemberRepository();
  });

  ProviderContainer createContainer({
    String? activeHouseholdId = 'shared',
    String? ownHouseholdId = 'own',
    List<Object> overrides = const <Object>[],
  }) {
    final container = ProviderContainer(
      overrides: [
        householdDataOwnerUserIdProvider.overrideWithValue(activeHouseholdId),
        ownHouseholdIdProvider.overrideWithValue(ownHouseholdId),
        householdInviteRepositoryProvider.overrideWithValue(invites),
        householdRepositoryProvider.overrideWithValue(households),
        householdMemberRepositoryProvider.overrideWithValue(members),
        householdInviteCodeControllerProvider.overrideWith(
          _TestInviteCodeController.new,
        ),
        ...overrides.cast(),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  List<AsyncValue<void>> recordStates(ProviderContainer container) {
    final states = <AsyncValue<void>>[];
    final subscription = container.listen(
      householdMembershipControllerProvider,
      (_, next) => states.add(next),
    );
    addTearDown(subscription.close);
    return states;
  }

  test('joinHousehold joins from the own household and forgets the previous '
      'one', () async {
    final container = createContainer(activeHouseholdId: 'own');
    final states = recordStates(container);
    container
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(staleOwnerUserId: 'old', personalUserId: 'own');
    final recovery = container.listen(
      householdDataOwnerRecoveryProvider,
      (_, _) {},
    );
    addTearDown(recovery.close);

    await container
        .read(householdMembershipControllerProvider.notifier)
        .joinHousehold(_invite('AbCdEfGhIjKlMnOpQrSt'));

    expect(invites.joins, <(String, String, String)>[
      ('AbCdEfGhIjKlMnOpQrSt', 'own', 'own'),
    ]);
    expect(states.map((state) => state.isLoading), <bool>[true, false]);
    expect(states.last.hasError, isFalse);
    expect(container.read(householdDataOwnerRecoveryProvider), isNull);
    expect(container.read(householdInviteCodeControllerProvider).value, isNull);
  });

  test('joinHousehold sets the display name first', () async {
    final authRepository = FakeAuthRepository();
    final container = createContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );

    await container
        .read(householdMembershipControllerProvider.notifier)
        .joinHousehold(
          _invite('AbCdEfGhIjKlMnOpQrSt'),
          displayName: '  Alex  ',
        );

    expect(authRepository.guestNameUpdateCalls, 1);
    expect(authRepository.lastGuestDisplayName, 'Alex');
  });

  test('a failed join ends in an error state', () async {
    invites.error = const ExpiredHouseholdInviteCodeException();
    final container = createContainer();
    final states = recordStates(container);

    await expectLater(
      container
          .read(householdMembershipControllerProvider.notifier)
          .joinHousehold(_invite('AbCdEfGhIjKlMnOpQrSt')),
      throwsA(isA<ExpiredHouseholdInviteCodeException>()),
    );

    expect(states.map((state) => state.isLoading), <bool>[true, false]);
    expect(states.last.error, isA<ExpiredHouseholdInviteCodeException>());
  });

  test('leaveHousehold names the successor', () async {
    final container = createContainer();

    await container
        .read(householdMembershipControllerProvider.notifier)
        .leaveHousehold(successorUid: 'member-2');

    expect(households.leaves, <(String, String, String?)>[
      ('shared', 'own', 'member-2'),
    ]);
  });

  test('removeMember and makeAdmin act on the active household', () async {
    final container = createContainer();
    final controller = container.read(
      householdMembershipControllerProvider.notifier,
    );

    await controller.removeMember('member-2');
    await controller.makeAdmin('member-3');

    expect(members.calls, <String>[
      'remove shared member-2',
      'admin shared member-3',
    ]);
  });

  test('actions wait for the household ids', () async {
    final container = createContainer(ownHouseholdId: null);

    await expectLater(
      container
          .read(householdMembershipControllerProvider.notifier)
          .leaveHousehold(),
      throwsA(isA<HouseholdKeyUnavailableException>()),
    );
    expect(households.leaves, isEmpty);
  });

  test(
    'createKeyRestoreCode wraps the key for the member who lost it',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final keys = HouseholdKeyRepository(
        firestore: FakeFirebaseFirestore(),
        storage: const FlutterSecureStorage(),
      );
      final householdKey = await PayloadCipher.newDataKey();
      final container = createContainer(
        overrides: [
          householdKeyRepositoryProvider.overrideWithValue(keys),
          householdCipherProvider.overrideWithValue((
            householdId: 'shared',
            key: householdKey,
            cipher: PayloadCipher(householdKey),
          )),
        ],
      );

      final code = await container
          .read(householdMembershipControllerProvider.notifier)
          .createKeyRestoreCode('member-2');

      final restored = await keys.loadRestoredKey(
        householdId: 'shared',
        memberUid: 'member-2',
        code: code,
      );
      expect(await restored.extractBytes(), await householdKey.extractBytes());
    },
  );

  test('createKeyRestoreCode fails without the household key', () async {
    final container = createContainer(
      overrides: [householdCipherProvider.overrideWithValue(null)],
    );

    await expectLater(
      container
          .read(householdMembershipControllerProvider.notifier)
          .createKeyRestoreCode('member-2'),
      throwsA(isA<HouseholdKeyUnavailableException>()),
    );
    expect(
      container.read(householdMembershipControllerProvider).hasError,
      isTrue,
    );
  });
}
