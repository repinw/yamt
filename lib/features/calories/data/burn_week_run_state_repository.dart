import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

/// App-preferences storage key for Burn Week run state.
const burnWeekRunStatePreferenceKey = 'burn_week_run_state_v2';
const _logName = 'BurnWeekRunStateRepository';

/// Persistent store for Burn Week run state.
abstract interface class BurnWeekRunStateRepository {
  /// Reads saved Burn Week run state.
  Future<BurnWeekRunState> readState();

  /// Saves Burn Week run state.
  Future<bool> saveState(BurnWeekRunState state);
}

class _PendingAuthBurnWeekRunStateRepository
    implements BurnWeekRunStateRepository {
  const _PendingAuthBurnWeekRunStateRepository();

  @override
  Future<BurnWeekRunState> readState() async {
    return const BurnWeekRunState.initial();
  }

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    return false;
  }
}

/// App-preferences-backed Burn Week run state repository.
class AppPreferencesBurnWeekRunStateRepository
    implements BurnWeekRunStateRepository {
  /// Creates repository.
  const AppPreferencesBurnWeekRunStateRepository({
    required AppPreferences preferences,
    this.storageKey = burnWeekRunStatePreferenceKey,
  }) : _preferences = preferences;

  final AppPreferences _preferences;

  /// Storage key.
  final String storageKey;

  @override
  Future<BurnWeekRunState> readState() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const BurnWeekRunState.initial();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const BurnWeekRunState.initial();
      }
      return BurnWeekRunState.fromJson(decoded);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to decode Burn Week run state.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const BurnWeekRunState.initial();
    }
  }

  @override
  Future<bool> saveState(BurnWeekRunState state) {
    return _preferences.setString(storageKey, jsonEncode(state.toJson()));
  }
}

/// Burn Week run state repository provider.
final burnWeekRunStateRepositoryProvider = Provider<BurnWeekRunStateRepository>(
  (ref) {
    final authState = ref.watch(authStateChangesProvider);
    final currentUserId =
        authState.asData?.value?.uid ??
        ref.watch(firebaseAuthProvider).currentUser?.uid;
    final storageKey = resolveBurnWeekRunStateStorageKey(
      authStateIsLoading: authState.isLoading,
      currentUserId: currentUserId,
    );
    if (storageKey == null) {
      return const _PendingAuthBurnWeekRunStateRepository();
    }
    return AppPreferencesBurnWeekRunStateRepository(
      preferences: ref.watch(appPreferencesProvider),
      storageKey: storageKey,
    );
  },
);

/// Resolves the storage key for current auth state.
///
/// Returns `null` while auth is still loading and no user id is available yet,
/// so Burn state cannot accidentally write into the guest slot.
@visibleForTesting
String? resolveBurnWeekRunStateStorageKey({
  required bool authStateIsLoading,
  required String? currentUserId,
}) {
  final normalizedUserId = currentUserId?.trim();
  if (normalizedUserId != null && normalizedUserId.isNotEmpty) {
    return _burnWeekRunStatePreferenceKeyForUser(normalizedUserId);
  }
  if (authStateIsLoading) {
    return null;
  }
  return _burnWeekRunStatePreferenceKeyForUser(null);
}

String _burnWeekRunStatePreferenceKeyForUser(String? userId) {
  final normalizedUserId = userId?.trim();
  if (normalizedUserId == null || normalizedUserId.isEmpty) {
    return '$burnWeekRunStatePreferenceKey::guest';
  }
  return '$burnWeekRunStatePreferenceKey::$normalizedUserId';
}
