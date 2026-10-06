import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Keeps a provider alive while an action runs.
extension RefWhileAlive on Ref {
  /// Keeps this provider and [provider] alive while [action] runs, so a
  /// write finishes after its screen closes.
  Future<T> whileAlive<S, T>(
    ProviderListenable<S> provider,
    Future<T> Function(S value) action,
  ) async {
    final link = keepAlive();
    final subscription = listen(provider, (_, _) {});
    try {
      return await action(subscription.read());
    } finally {
      subscription.close();
      link.close();
    }
  }
}
