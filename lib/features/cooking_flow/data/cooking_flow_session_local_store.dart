import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

/// Shared-preferences key for persisted cookflow session snapshot.
const cookingFlowSessionPreferenceKey = 'cooking_flow_session_v1';
const _logName = 'CookingFlowSessionLocalStore';

/// Local persistence contract for cookflow session snapshots.
abstract interface class CookingFlowSessionLocalStore {
  /// Loads saved session when present.
  Future<CookingFlowSession?> load();

  /// Saves session snapshot.
  Future<bool> save(CookingFlowSession session);

  /// Clears saved session snapshot.
  Future<bool> clear();
}

/// Watches the current persisted cookflow session snapshot.
final FutureProvider<CookingFlowSession?> cookingFlowSessionSnapshotProvider =
    FutureProvider<CookingFlowSession?>((ref) async {
      return ref.watch(cookingFlowSessionLocalStoreProvider).load();
    });

/// Reactive session access used by cookflow UI.
class CookingFlowSessionCoordinator {
  /// Creates coordinator.
  const CookingFlowSessionCoordinator(this._ref);

  final Ref _ref;

  /// Loads current session.
  Future<CookingFlowSession?> load() {
    return _ref.read(cookingFlowSessionLocalStoreProvider).load();
  }

  /// Saves current session and notifies listeners on success.
  Future<bool> save(CookingFlowSession session) async {
    final saved = await _ref
        .read(cookingFlowSessionLocalStoreProvider)
        .save(
          session,
        );
    if (saved) {
      _refreshSnapshot();
    }
    return saved;
  }

  /// Clears current session and notifies listeners on success.
  Future<bool> clear() async {
    final cleared = await _ref
        .read(cookingFlowSessionLocalStoreProvider)
        .clear();
    if (cleared) {
      _refreshSnapshot();
    }
    return cleared;
  }

  void _refreshSnapshot() {
    _ref.invalidate(cookingFlowSessionSnapshotProvider);
  }
}

/// Provides reactive cookflow session coordinator.
final Provider<CookingFlowSessionCoordinator>
cookingFlowSessionCoordinatorProvider = Provider<CookingFlowSessionCoordinator>(
  (ref) {
    return CookingFlowSessionCoordinator(ref);
  },
);

/// Shared-preferences-backed cookflow session store.
class AppPreferencesCookingFlowSessionLocalStore
    implements CookingFlowSessionLocalStore {
  /// Creates local store.
  AppPreferencesCookingFlowSessionLocalStore({
    required AppPreferences preferences,
    this.storageKey = cookingFlowSessionPreferenceKey,
  }) : _preferences = preferences;

  final AppPreferences _preferences;

  /// Preference key used by this store instance.
  final String storageKey;

  @override
  Future<CookingFlowSession?> load() async {
    final rawValue = await _preferences.getString(storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return CookingFlowSession.fromJson(decoded);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to decode cookflow session.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<bool> save(CookingFlowSession session) {
    final encoded = jsonEncode(session.toJson());
    return _preferences.setString(storageKey, encoded);
  }

  @override
  Future<bool> clear() {
    return _preferences.setString(storageKey, '');
  }
}

/// Provides local cookflow session store.
final cookingFlowSessionLocalStoreProvider =
    Provider<CookingFlowSessionLocalStore>((ref) {
      return AppPreferencesCookingFlowSessionLocalStore(
        preferences: ref.watch(appPreferencesProvider),
      );
    });
