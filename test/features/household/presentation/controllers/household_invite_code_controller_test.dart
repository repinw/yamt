import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_invite_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/presentation/controllers/'
    'household_invite_code_controller.dart';

class _FakeInviteRepository extends Fake implements HouseholdInviteRepository {
  final households = <String>[];
  Exception? error;

  @override
  Future<HouseholdInvite> generateInvite(String householdId) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    households.add(householdId);
    return HouseholdInvite(
      code: 'AbCdEfGhIjKlMnOpQrSt',
      secret: RecoveryKey.generate(),
    );
  }
}

void main() {
  late _FakeInviteRepository repository;

  setUp(() => repository = _FakeInviteRepository());

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        householdDataOwnerUserIdProvider.overrideWithValue('own'),
        householdInviteRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('generateInviteCode invites into the active household', () async {
    final container = createContainer();
    final states = <AsyncValue<HouseholdInvite?>>[];
    final subscription = container.listen(
      householdInviteCodeControllerProvider,
      (_, next) => states.add(next),
    );
    addTearDown(subscription.close);

    await container
        .read(householdInviteCodeControllerProvider.notifier)
        .generateInviteCode();

    expect(repository.households, <String>['own']);
    expect(states.first.isLoading, isTrue);
    expect(states.last.value?.code, 'AbCdEfGhIjKlMnOpQrSt');

    container.read(householdInviteCodeControllerProvider.notifier).clear();
    expect(container.read(householdInviteCodeControllerProvider).value, isNull);
  });

  test('a failed invite ends in an error state', () async {
    repository.error = const HouseholdAdminRequiredException();
    final container = createContainer();
    final subscription = container.listen(
      householdInviteCodeControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await expectLater(
      container
          .read(householdInviteCodeControllerProvider.notifier)
          .generateInviteCode(),
      throwsA(isA<HouseholdAdminRequiredException>()),
    );
    expect(
      container.read(householdInviteCodeControllerProvider).error,
      isA<HouseholdAdminRequiredException>(),
    );
  });
}
