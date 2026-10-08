import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';

import '../../calories/support/fake_calories_repositories.dart';
import '../../calories/support/fake_planned_entry_repository.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

/// The current time in quick entry tests.
final quickEntryNow = DateTime(2026, 9, 28, 12, 30);

/// Lets the quick entry page save to [calorieLog], and plans to [plans], as
/// `user-1` at [quickEntryNow], or at the time of [clock].
List<Override> quickEntryOverrides(
  FakeCalorieLogRepository calorieLog, {
  FakePlannedEntryRepository? plans,
  DateTime Function()? clock,
}) {
  final auth = _MockFirebaseAuth();
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  when(() => auth.currentUser).thenReturn(user);
  return [
    calorieLogRepositoryProvider.overrideWithValue(calorieLog),
    plannedEntryRepositoryProvider.overrideWithValue(
      plans ?? FakePlannedEntryRepository(),
    ),
    firebaseAuthProvider.overrideWithValue(auth),
    clockProvider.overrideWithValue(clock ?? () => quickEntryNow),
  ];
}
