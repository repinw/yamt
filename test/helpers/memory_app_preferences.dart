import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/domain/'
    'auth_profile_setup_preferences.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';

class MemoryAppPreferences implements AppPreferences {
  MemoryAppPreferences({
    Set<String> completedProfileSetupUserIds = const <String>{},
    Set<String> completedCalorieGoalOnboardingUserIds = const <String>{},
    Map<String, String>? initialStrings,
    Map<String, int>? initialInts,
  }) {
    if (initialStrings != null) {
      _strings.addAll(initialStrings);
    }
    if (initialInts != null) {
      _ints.addAll(initialInts);
    }
    for (final userId in completedProfileSetupUserIds) {
      final key = AuthProfileSetupPreferences.keyForUser(userId);
      _strings[key] = AuthProfileSetupPreferences.completedValue;
    }
    for (final userId in completedCalorieGoalOnboardingUserIds) {
      final key = calorieGoalOnboardingKeyForUser(userId);
      _strings[key] = calorieGoalOnboardingCompletedValue;
    }
  }

  final Map<String, String> _strings = <String, String>{};
  final Map<String, int> _ints = <String, int>{};

  @override
  String? getStringSync(String key) => _strings[key];

  @override
  int? getIntSync(String key) => _ints[key];

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<bool> setString(String key, String value) async {
    _strings[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _ints[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _strings.remove(key);
    _ints.remove(key);
    return true;
  }
}
