import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _providerObserverLogName = 'RiverpodDebug';

/// Logs provider lifecycle changes in debug builds.
final class AppProviderObserver extends ProviderObserver {
  /// Creates provider observer.
  const AppProviderObserver();

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    log(
      '[add] ${_providerLabel(context)} = ${_describeValue(value)}',
      name: _providerObserverLogName,
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final previousSummary = _describeValue(previousValue);
    final nextSummary = _describeValue(newValue);
    if (previousSummary == nextSummary) {
      return;
    }

    final mutation = context.mutation == null
        ? ''
        : ' mutation=${describeIdentity(context.mutation)}';
    log(
      '[update] ${_providerLabel(context)}: '
      '$previousSummary -> $nextSummary$mutation',
      name: _providerObserverLogName,
    );
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    log(
      '[error] ${_providerLabel(context)}: ${Error.safeToString(error)}',
      name: _providerObserverLogName,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

String _providerLabel(ProviderObserverContext context) {
  final provider = context.provider;
  final name = provider.name;
  if (name != null && name.isNotEmpty) {
    return name;
  }
  return provider.toString();
}

String _describeValue(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is AsyncLoading) {
    return 'AsyncLoading';
  }
  if (value case AsyncData(:final value)) {
    return 'AsyncData(${_compactValue(value)})';
  }
  if (value case AsyncError(:final error)) {
    return 'AsyncError(${Error.safeToString(error)})';
  }
  return _compactValue(value);
}

String _compactValue(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return value.length <= 48 ? '"$value"' : '"${value.substring(0, 45)}..."';
  }
  if (value is Iterable) {
    return '${value.runtimeType}(len=${value.length})';
  }
  if (value is Map) {
    return '${value.runtimeType}(len=${value.length})';
  }
  return Error.safeToString(value);
}
