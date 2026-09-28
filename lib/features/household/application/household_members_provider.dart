import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/domain/household_member.dart';

part 'household_members_provider.g.dart';

/// The members of the active household, the admin first, then by the day
/// they joined. Empty while there is no household yet.
@riverpod
Stream<List<HouseholdMember>> householdMembers(Ref ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  final repository = ref.watch(householdMemberRepositoryProvider);
  if (householdId == null || repository == null) {
    return Stream<List<HouseholdMember>>.value(const <HouseholdMember>[]);
  }
  return repository.watchMembers(householdId);
}

/// The other members of the active household who wait for its key after a
/// fresh start.
@riverpod
Stream<List<HouseholdMember>> householdKeyRestoreRequests(Ref ref) async* {
  final householdId = ref.watch(activeHouseholdIdProvider);
  final uid = ref.watch(userDataCipherProvider)?.uid;
  final keys = ref.watch(householdKeyRepositoryProvider);
  final membersFuture = ref.watch(householdMembersProvider.future);
  if (householdId == null || uid == null || keys == null) {
    yield const <HouseholdMember>[];
    return;
  }
  final members = await membersFuture;
  yield* keys
      .watchKeyRestoreRequests(householdId)
      .map(
        (uids) => members
            .where((member) => member.uid != uid && uids.contains(member.uid))
            .toList(growable: false),
      );
}
