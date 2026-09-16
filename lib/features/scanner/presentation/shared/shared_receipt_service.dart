import 'dart:async';
import 'dart:developer' show log;

import 'package:file_share_intent/file_share_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/presentation/shared/pending_shared_receipt_paths.dart';

part 'shared_receipt_service.g.dart';

const String _logName = 'SharedReceiptService';
const _supportedExtensions = {'.pdf', '.jpg', '.jpeg', '.png', '.webp'};

/// Provides platform [FileShareIntent] instance.
@Riverpod(keepAlive: true)
FileShareIntent fileShareIntent(Ref ref) {
  return FileShareIntent.instance;
}

/// Service that monitors platform file share intents and pushes valid paths
/// to [PendingSharedReceiptPaths].
@Riverpod(keepAlive: true)
class SharedReceiptService extends _$SharedReceiptService {
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;

  @override
  Future<void> build() async {
    if (!_isSharePlatformSupported()) return;

    final intentPlugin = ref.watch(fileShareIntentProvider);
    try {
      _mediaSubscription = intentPlugin.getMediaStream().listen(
        (files) {
          if (files.isEmpty) return;
          unawaited(_handleSharedFiles(intentPlugin, files));
        },
        onError: (Object error, StackTrace stackTrace) {
          log(
            'Shared receipt stream error: $error',
            name: _logName,
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      final initialMedia = await intentPlugin.getInitialMedia();
      if (!ref.mounted) return;
      if (initialMedia.isNotEmpty) {
        await _handleSharedFiles(intentPlugin, initialMedia);
      } else {
        await _resetConsumedShare(intentPlugin);
      }
    } on MissingPluginException catch (error, stackTrace) {
      log(
        'FileShareIntent plugin missing: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Shared receipt service setup failed: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }

    ref.onDispose(() {
      unawaited(_mediaSubscription?.cancel());
    });
  }

  Future<void> _handleSharedFiles(
    FileShareIntent intentPlugin,
    List<SharedMediaFile> files,
  ) async {
    try {
      final validPaths = files
          .map((f) => f.path.trim())
          .where((path) {
            final lower = path.toLowerCase();
            return _supportedExtensions.any(lower.endsWith);
          })
          .toList(growable: false);

      if (validPaths.isEmpty) {
        log('No supported receipt files found in share.', name: _logName);
        return;
      }

      log(
        'Received ${validPaths.length} shared receipt file(s).',
        name: _logName,
      );
      if (!ref.mounted) return;
      ref.read(pendingSharedReceiptPathsProvider.notifier).setPaths(validPaths);
    } finally {
      await _resetConsumedShare(intentPlugin);
    }
  }

  Future<void> _resetConsumedShare(FileShareIntent intentPlugin) async {
    try {
      await intentPlugin.reset();
    } on MissingPluginException {
      // Optional in tests.
    } on Object catch (error, stackTrace) {
      log(
        'Shared receipt reset failed: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static bool _isSharePlatformSupported() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => false,
    };
  }
}
