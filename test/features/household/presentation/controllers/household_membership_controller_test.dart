import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/household_invite_code_controller.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_membership_controller.dart';

import '../../../../helpers/fake_auth_repository.dart';
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
}
