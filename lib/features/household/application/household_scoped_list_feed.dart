import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/household/application/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';

/// The list of a household scoped collection that a controller shows.
///
/// It watches the collection of the active household, keeps the newest list,
/// and hands it to the controller's state. When the watch is denied in a
/// household the user left, it switches to the own household and starts
/// again. Each start begins a new [generation]; lists and errors of an
/// earlier one are ignored.
///
/// It is a part of its controller and gets that controller's ref, as the
/// household access recovery helpers next to it do. It holds no state of
/// its own beyond the watch and the newest list.
class HouseholdScopedListFeed<T> {
  /// Creates the feed for the controller behind ref; watch and readAll
  /// reach the collection of the active household.
  new({
    required this._ref,
    required this._watch,
    required this._readAll,
    required this._setState,
    required this._logName,
    required this._recoveryMessage,
  });

  /// The controller's ref of its current build; Riverpod makes a new one
  /// for each build.
  final Ref Function() _ref;
  final Stream<List<T>> Function() _watch;
  final Future<List<T>> Function() _readAll;
  final void Function(AsyncValue<List<T>> state) _setState;
  final String _logName;
  final String _recoveryMessage;

  StreamSubscription<List<T>>? _subscription;
  String? _householdId;
  bool _isRecovering = false;
  List<T>? _items;

  int _generation = 0;

  /// Counts the starts; a change begun in an earlier one is out of date.
  int get generation => _generation;

  /// The newest list: the last one streamed or published, or null before
  /// the first one.
  List<T>? get items => _items;

  /// The newest list; before the first one it reads the collection.
  Future<List<T>> current() async {
    final items = _items;
    if (items != null || !_ref().mounted) {
      return items ?? <T>[];
    }
    final read = await _readAll();
    if (_ref().mounted) {
      _items = read;
    }
    return read;
  }

  /// Keeps [items] as the newest list and shows it.
  void publish(List<T> items) {
    _items = items;
    if (_ref().mounted) {
      _setState(AsyncData(items));
    }
  }

  /// Watches the active household again and completes with its first list.
  Future<List<T>> start() async {
    final first = Completer<List<T>>();
    _householdId = _ref().read(activeHouseholdIdProvider);
    final started = ++_generation;
    final stream = _watch();
    await close();
    _items = null;
    if (!_ref().mounted) {
      return <T>[];
    }
    _subscription = stream.listen(
      (items) {
        if (started != _generation) {
          return;
        }
        _items = items;
        if (!first.isCompleted) {
          first.complete(items);
          return;
        }
        publish(items);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (started != _generation) {
          return;
        }
        if (!first.isCompleted) {
          if (_shouldRecover(error)) {
            first.complete(<T>[]);
            unawaited(_recover(showLoading: false));
            return;
          }
          first.completeError(error, stackTrace);
          return;
        }
        if (_shouldRecover(error)) {
          unawaited(_recover());
          return;
        }
        if (_ref().mounted) {
          _setState(AsyncError(error, stackTrace));
        }
      },
    );
    return await first.future;
  }

  /// Shows loading, starts again, and shows the result.
  Future<void> refresh() async {
    _setState(const AsyncLoading());
    final next = await AsyncValue.guard(start);
    if (_ref().mounted) {
      _setState(next);
    }
  }

  /// Stops watching.
  Future<void> close() async {
    final cancelled = _subscription?.cancel();
    _subscription = null;
    await cancelled;
  }

  bool _shouldRecover(Object error) {
    final shouldRecover = shouldRecoverControllerHouseholdAccess(
      ref: _ref(),
      error: error,
      isRecoveringHouseholdAccess: _isRecovering,
      currentHouseholdDataOwnerUserId: _householdId,
    );
    if (error is FirebaseException && error.code == 'permission-denied') {
      _logScope(
        'Permission denied while watching. '
        'shouldRecover=$shouldRecover',
      );
    }
    return shouldRecover;
  }

  Future<void> _recover({bool showLoading = true}) {
    return recoverControllerHouseholdAccess<T>(
      ref: _ref(),
      isRecoveringHouseholdAccess: _isRecovering,
      setIsRecoveringHouseholdAccess: ({required value}) {
        _isRecovering = value;
      },
      setState: _setState,
      restartHouseholdScopedSubscription: start,
      currentHouseholdDataOwnerUserId: _householdId,
      householdAccessRecoveryLogName: _logName,
      householdAccessRecoveryMessage: _recoveryMessage,
      showLoading: showLoading,
      onSkippedHouseholdAccessRecovery: () =>
          _logScope('Access recovery had no owner swap candidate.'),
    );
  }

  void _logScope(String message) {
    final scope = householdScopeDebugDetails(
      _ref(),
      controllerHouseholdId: _householdId,
    );
    log('$message $scope', name: _logName);
  }
}
