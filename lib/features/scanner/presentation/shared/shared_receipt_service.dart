import 'dart:async';
import 'dart:developer' show log;

import 'package:file_share_intent/file_share_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/pending_shared_text.dart';
import 'package:yamt/core/device/pending_unreadable_share.dart';
import 'package:yamt/features/scanner/presentation/shared/pending_shared_receipt_paths.dart';

part 'shared_receipt_service.g.dart';

const String _logName = 'SharedReceiptService';
const _supportedExtensions = {'.pdf', '.jpg', '.jpeg', '.png', '.webp'};

/// Tells Android that the share stream listens (`MainActivity.kt`).
const _shareReadyChannel = MethodChannel('de.yamt.app/share_ready');

/// Shared items that carry their text or link as the path.
const Set<SharedMediaType> _textTypes = {
  SharedMediaType.text,
  SharedMediaType.url,
};

final _absolutePath = RegExp(r'/\S');
final _appLink = RegExp('yamt://', caseSensitive: false);

/// Whether [file] carries text or a link as its path. Android types a shared
/// file as text when the sender adds a text to it, and keeps the file path,
/// so a single line that starts with a path is a file of any kind.
bool _isText(SharedMediaFile file) {
  if (!_textTypes.contains(file.type)) return false;
  final path = file.path.trim();
  return !path.startsWith(_absolutePath) || path.contains('\n');
}

/// Whether [file] holds a link into this app, such as a household invite,
/// anywhere in its text. Its secret must never reach a recipe text or the AI.
bool _isAppLink(SharedMediaFile file) => _appLink.hasMatch(file.path);

/// Provides platform [FileShareIntent] instance.
@Riverpod(keepAlive: true)
FileShareIntent fileShareIntent(Ref ref) {
  return FileShareIntent.instance;
}

/// Service that monitors platform file share intents and pushes valid paths
/// to [PendingSharedReceiptPaths]. Shared text and links go to
/// [PendingSharedText], and a share we cannot read raises
/// [PendingUnreadableShare].
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
          _raiseUnreadable();
        },
      );
      unawaited(_tellShareStreamListens());

      final initialMedia = await _initialMedia(intentPlugin);
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

  /// Lets Android hand over a share that came before the stream listened.
  /// Sent without waiting, so it stays between the stream's start and the
  /// question for the initial share, and goes out even when that one fails.
  Future<void> _tellShareStreamListens() async {
    try {
      await _shareReadyChannel.invokeMethod<void>('ready');
    } on MissingPluginException {
      // Only Android has this channel.
    } on Object catch (error, stackTrace) {
      log(
        'Telling Android about the share stream failed: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The share that started the app. The plugin throws a [TypeError] for a
  /// share that carries neither a file nor a text it can read.
  Future<List<SharedMediaFile>> _initialMedia(
    FileShareIntent intentPlugin,
  ) async {
    try {
      return await intentPlugin.getInitialMedia();
    } on Object catch (error, stackTrace) {
      if (error is! TypeError) rethrow;
      log(
        'Shared item unreadable: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      _raiseUnreadable();
      return const [];
    }
  }

  void _raiseUnreadable() {
    if (ref.mounted) {
      ref.read(pendingUnreadableShareProvider.notifier).raise();
    }
  }

  Future<void> _handleSharedFiles(
    FileShareIntent intentPlugin,
    List<SharedMediaFile> files,
  ) async {
    try {
      final text = files
          .where(_isText)
          .where((f) => !_isAppLink(f))
          .map((f) => f.path)
          .join('\n');
      if (text.trim().isNotEmpty && ref.mounted) {
        ref.read(pendingSharedTextProvider.notifier).put(text);
      }
      final validPaths = files
          .where((f) => !_isText(f))
          .map((f) => f.path.trim())
          .where((path) {
            final lower = path.toLowerCase();
            return _supportedExtensions.any(lower.endsWith);
          })
          .toList(growable: false);

      if (validPaths.isEmpty) {
        log('No supported receipt files found in share.', name: _logName);
        // A link into the app that opened it goes to the router instead.
        final openedByAppLink = files.any(
          (f) => f.type == SharedMediaType.url && _isAppLink(f),
        );
        if (text.trim().isEmpty && !openedByAppLink) {
          _raiseUnreadable();
        }
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
