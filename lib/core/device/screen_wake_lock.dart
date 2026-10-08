import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'screen_wake_lock.g.dart';

/// Keeps the screen on while at least one page holds it.
///
/// Pages call [acquire] when they open and [release] when they close. The
/// count lets one cooking page replace another without the screen turning
/// off in between. The platform lock only acts while the app is in the
/// foreground, so the background needs no handling here.
class ScreenWakeLock {
  /// Creates the lock; [toggle] switches the platform lock.
  new({Future<void> Function({required bool on})? toggle})
    : _toggle = toggle ?? (({required on}) => WakelockPlus.toggle(enable: on));

  final Future<void> Function({required bool on}) _toggle;
  int _holders = 0;

  /// Keeps the screen on until the matching [release].
  void acquire() {
    if (_holders++ == 0) _switch(on: true);
  }

  /// Ends one [acquire]; the screen may turn off after the last one.
  void release() {
    if (_holders == 0) return;
    if (--_holders == 0) _switch(on: false);
  }

  // A failed switch only means the screen turns off as usual.
  void _switch({required bool on}) => unawaited(
    _toggle(on: on).catchError((Object error) {
      log('Screen wake lock failed: $error', name: 'ScreenWakeLock');
    }),
  );
}

/// The app's screen wake lock. Kept alive, so all pages share one count.
@Riverpod(keepAlive: true)
ScreenWakeLock screenWakeLock(Ref ref) => ScreenWakeLock();
