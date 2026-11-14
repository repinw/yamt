import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';

/// Temporary migration, added in 3.11.0: removed in 3.14.0. Decides whether
/// the list controller may rewrite stored entries from before the done flag:
/// an app below the minimum version must not, and until the update status is
/// known the entries stay as they are.
class ShoppingListRewriteGate {
  AppUpdateStatus? _status;

  /// Follows the update status from a provider's build; [onArrived] runs
  /// when the status first arrives after the build.
  void listen(Ref ref, void Function() onArrived) {
    _status = null;
    ref.listen(
      appUpdateStatusProvider,
      (previous, next) {
        if (next case AsyncError(:final error, :final stackTrace)) {
          _logError(error, stackTrace);
        }
        final known = _status != null;
        _status = next.value;
        if (previous != null && !known && _status != null) onArrived();
      },
      onError: _logError,
      fireImmediately: true,
    );
  }

  /// Whether [repository] holds old entries that this app may rewrite now.
  bool allows(ShoppingListRepository repository) {
    final status = _status;
    return repository.holdsUnmigratedItems &&
        status != null &&
        status is! AppUpdateRequired;
  }

  void _logError(Object error, StackTrace stack) => log(
    'App update status failed; old shopping entries stay unmigrated.',
    name: 'ShoppingListRewriteGate',
    error: error,
    stackTrace: stack,
  );
}
