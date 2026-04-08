import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/provider/household_invite_code_controller.dart';
import 'package:yamt/features/household/provider/'
    'household_membership_controller.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

class _TestHouseholdInviteCodeController extends HouseholdInviteCodeController {
  _TestHouseholdInviteCodeController({required this.initialCode});

  final String? initialCode;

  @override
  AsyncValue<String?> build() {
    return AsyncData<String?>(initialCode);
  }
}

void main() {
  test('joinHousehold clears recovery state and invite code', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('household_invites').doc('123456').set({
      'hostUid': 'host-1',
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 1)),
      ),
    });
    final repository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'member-1',
      isAnonymous: true,
      currentHouseholdId: null,
    );
    final inviteCodeController = _TestHouseholdInviteCodeController(
      initialCode: '123456',
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
        .joinHousehold('123456');

    expect(container.read(householdDataOwnerRecoveryProvider), isNull);
    expect(
      container.read(householdInviteCodeControllerProvider).asData?.value,
      isNull,
    );
  });

  test('leaveHousehold clears recovery state and invite code', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('member-1').set({
      'uid': 'member-1',
      'householdId': 'host-1',
    });
    final repository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'member-1',
      isAnonymous: false,
      currentHouseholdId: 'host-1',
    );
    final inviteCodeController = _TestHouseholdInviteCodeController(
      initialCode: '654321',
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
