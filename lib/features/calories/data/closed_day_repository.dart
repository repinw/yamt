import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'closed_day_repository.g.dart';

const _closedDayKeyPrefix = 'calorie_closed_day_v1';

/// Stores the day the signed-in user closed early, so the next day plans
/// with its carryover. It is saved on this device only.
///
/// Only today can be closed, and a past day always counts as finished, so the
/// value matters until midnight only.
class ClosedDayRepository {
  /// Creates the repository on the device preferences for [userId], or for
  /// nobody while signed out.
  const new(this._preferences, this.userId);

  final AppPreferences _preferences;

  /// The signed-in user, or null while signed out.
  final String? userId;

  /// The closed day, or null when no day is closed or nobody is signed in.
  DateTime? readClosedDay() {
    final userId = this.userId;
    if (userId == null) {
      return null;
    }
    final stored = _preferences.getStringSync(_key(userId));
    return stored == null ? null : DateTime.parse(stored);
  }

  /// Saves [day] as closed. Throws while signed out or when the device does
  /// not save it.
  Future<void> saveClosedDay(DateTime day) async {
    final saved = await _preferences.setString(
      _key(_requireUserId()),
      normalizeDiaryDay(day).toIso8601String(),
    );
    if (!saved) {
      throw StateError('The closed day was not saved.');
    }
  }

  /// Deletes the closed day. Throws while signed out or when the device does
  /// not save it.
  Future<void> deleteClosedDay() async {
    if (!await _preferences.remove(_key(_requireUserId()))) {
      throw StateError('The closed day was not deleted.');
    }
  }

  String _requireUserId() =>
      userId ?? (throw StateError('No signed-in user for the closed day.'));

  static String _key(String userId) => '$_closedDayKeyPrefix:$userId';
}

/// Closed day repository of the signed-in user.
@riverpod
ClosedDayRepository closedDayRepository(Ref ref) => ClosedDayRepository(
  ref.watch(appPreferencesProvider),
  ref.watch(authStateChangesProvider).asData?.value?.uid,
);
