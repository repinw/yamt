import 'dart:async';
import 'dart:developer' show log;

import 'package:file_share_intent/file_share_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_input_repository.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/shared_receipt_intent.dart';

part 'shared_receipt_service.g.dart';

const String _sharedReceiptServiceLogName = 'SharedReceiptService';

@riverpod
FileShareIntent fileShareIntent(Ref ref) {
  return FileShareIntent.instance;
}

@riverpod
class PendingSharedReceiptIntent extends _$PendingSharedReceiptIntent {
  @override
  SharedReceiptIntent? build() {
    return null;
  }

  void replace(List<ReceiptInputSelection> selections) {
    if (selections.isEmpty) {
      return;
    }

    state = SharedReceiptIntent(
      requestId: DateTime.now().microsecondsSinceEpoch,
      selections: List.unmodifiable(selections),
    );
  }

  void consume(int requestId) {
    if (state?.requestId != requestId) {
      return;
    }
    state = null;
  }
}

@Riverpod(keepAlive: true)
class SharedReceiptService extends _$SharedReceiptService {
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;

  @override
  Future<void> build() async {
    if (!_isSharePlatformSupported()) {
      return;
    }

    final intentPlugin = ref.watch(fileShareIntentProvider);
    try {
      _mediaSubscription = intentPlugin.getMediaStream().listen(
        (files) {
          if (files.isEmpty) {
            return;
          }
          unawaited(_handleSharedFiles(intentPlugin, files));
        },
        onError: (Object error, StackTrace stackTrace) {
          log(
            'Shared receipt stream failed.',
            name: _sharedReceiptServiceLogName,
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      final initialMedia = await intentPlugin.getInitialMedia();
      if (initialMedia.isNotEmpty) {
        await _handleSharedFiles(intentPlugin, initialMedia);
      } else {
        await _resetConsumedShare(intentPlugin);
      }
    } on MissingPluginException catch (error, stackTrace) {
      log(
        'FileShareIntent plugin is not available on this platform.',
        name: _sharedReceiptServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      log(
        'Shared receipt service setup failed.',
        name: _sharedReceiptServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }

    ref.onDispose(() {
      _mediaSubscription?.cancel();
    });
  }

  Future<void> _handleSharedFiles(
    FileShareIntent intentPlugin,
    List<SharedMediaFile> files,
  ) async {
    try {
      final selections = await loadSharedReceiptSelectionsFromPaths(
        files.map((file) => file.path),
      );
      if (selections.isEmpty) {
        log(
          'Ignored shared files because no supported receipt files could '
          'be loaded.',
          name: _sharedReceiptServiceLogName,
        );
        return;
      }

      log(
        'Received ${selections.length} shared receipt file(s).',
        name: _sharedReceiptServiceLogName,
      );
      ref.read(pendingSharedReceiptIntentProvider.notifier).replace(selections);
    } catch (error, stackTrace) {
      log(
        'Shared receipt import failed.',
        name: _sharedReceiptServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await _resetConsumedShare(intentPlugin);
    }
  }

  Future<void> _resetConsumedShare(FileShareIntent intentPlugin) async {
    try {
      await intentPlugin.reset();
    } on MissingPluginException {
      // Plugin is optional in tests and on unsupported platforms.
    } catch (error, stackTrace) {
      log(
        'Shared receipt reset failed.',
        name: _sharedReceiptServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

bool _isSharePlatformSupported() {
  if (kIsWeb) {
    return false;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => false,
  };
}
