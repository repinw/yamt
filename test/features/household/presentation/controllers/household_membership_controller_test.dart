import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/data/household_reset_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';
import 'package:yamt/features/household/presentation/controllers/household_invite_code_controller.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_firebase_storage.dart';
import '../../../../helpers/memory_app_preferences.dart';

class _TestHouseholdInviteCodeController extends HouseholdInviteCodeController {
  new({required this.initialInvite});

  final HouseholdInvite? initialInvite;

  @override
  AsyncValue<HouseholdInvite?> build() {
    return AsyncData<HouseholdInvite?>(initialInvite);
  }
}

class _MockHouseholdRepository extends Mock implements HouseholdRepository;

HouseholdInvite _invite(String code) {
  return HouseholdInvite(code: code, secret: RecoveryKey.generate());
}

void main() {
  late _MockHouseholdRepository repository;

  setUpAll(() {
    registerFallbackValue(_invite('000000'));
  });

  setUp(() {
    repository = _MockHouseholdRepository();
    when(() => repository.joinHousehold(any())).thenAnswer((_) async {});
    when(repository.leaveHousehold).thenAnswer((_) async {});
  });

  test('joinHousehold clears recovery state and invite code', () async {
    final inviteCodeController = _TestHouseholdInviteCodeController(
      initialInvite: _invite('123456'),
    );
    final container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repository),
        householdInviteCodeControllerProvider.overrideWith(
          () => inviteCodeController,
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(
          staleOwnerUserId: 'host-1',
          personalUserId: 'member-1',
        );

    await container
        .read(householdMembershipControllerProvider.notifier)
        .joinHousehold(_invite('123456'));

    expect(container.read(householdDataOwnerRecoveryProvider), isNull);
    expect(
      container.read(householdInviteCodeControllerProvider).asData?.value,
      isNull,
    );
  });

  test('joinHousehold updates displayName when provided', () async {
    final fakeAuthRepository = FakeAuthRepository();
    final memoryPreferences = MemoryAppPreferences();
    final container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repository),
        householdInviteCodeControllerProvider.overrideWith(
          () => _TestHouseholdInviteCodeController(initialInvite: null),
        ),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        appPreferencesProvider.overrideWithValue(memoryPreferences),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(householdMembershipControllerProvider.notifier)
        .joinHousehold(_invite('123456'), displayName: '  Alex  ');

    expect(fakeAuthRepository.guestNameUpdateCalls, 1);
    expect(fakeAuthRepository.lastGuestDisplayName, 'Alex');
  });

  test('leaveHousehold clears recovery state and invite code', () async {
    final inviteCodeController = _TestHouseholdInviteCodeController(
      initialInvite: _invite('654321'),
    );
    final container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repository),
        householdInviteCodeControllerProvider.overrideWith(
          () => inviteCodeController,
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(householdDataOwnerRecoveryProvider.notifier)
        .recoverToPersonalScope(
          staleOwnerUserId: 'host-1',
          personalUserId: 'member-1',
        );

    await container
        .read(householdMembershipControllerProvider.notifier)
        .leaveHousehold();

    expect(container.read(householdDataOwnerRecoveryProvider), isNull);
    expect(
      container.read(householdInviteCodeControllerProvider).asData?.value,
      isNull,
    );
  });

  test('createKeyRestoreCode wraps the household key for the host', () async {
    final householdKey = await PayloadCipher.newDataKey();
    final firestore = FakeFirebaseFirestore();
    final resets = HouseholdResetRepository(
      firestore: firestore,
      storage: FakeFirebaseStorage(),
    );
    final container = ProviderContainer(
      overrides: [
        householdCipherProvider.overrideWithValue((
          ownerUid: 'host-1',
          key: householdKey,
          cipher: PayloadCipher(householdKey),
        )),
        householdResetRepositoryProvider.overrideWithValue(resets),
      ],
    );
    addTearDown(container.dispose);

    final code = await container
        .read(householdMembershipControllerProvider.notifier)
        .createKeyRestoreCode();

    final restored = await resets.loadRestoredKey(
      ownerUid: 'host-1',
      code: code,
    );
    expect(await restored.extractBytes(), await householdKey.extractBytes());
  });

  test('createKeyRestoreCode fails without the household key', () async {
    final container = ProviderContainer(
      overrides: [
        householdCipherProvider.overrideWithValue(null),
        householdResetRepositoryProvider.overrideWithValue(
          HouseholdResetRepository(
            firestore: FakeFirebaseFirestore(),
            storage: FakeFirebaseStorage(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(householdMembershipControllerProvider.notifier)
          .createKeyRestoreCode(),
      throwsA(isA<HouseholdKeyUnavailableException>()),
    );
    expect(
      container.read(householdMembershipControllerProvider).hasError,
      isTrue,
    );
  });
}
