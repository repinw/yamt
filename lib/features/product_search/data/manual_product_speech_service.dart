import 'dart:developer' show log;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

const _manualProductSpeechServiceLogName = 'ManualProductSpeechService';

enum ManualProductSpeechFailure { unavailable, permissionDenied, error }

class ManualProductSpeechRecognition {
  const ManualProductSpeechRecognition({
    required this.transcript,
    required this.isFinal,
  });

  final String transcript;
  final bool isFinal;
}

abstract class ManualProductSpeechService {
  bool get isListening;

  Future<ManualProductSpeechFailure?> startListening({
    required ValueChanged<ManualProductSpeechRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<ManualProductSpeechFailure> onError,
  });

  Future<void> stopListening();

  Future<void> cancelListening();
}

final manualProductSpeechServiceProvider = Provider<ManualProductSpeechService>(
  (ref) => SpeechToTextManualProductSpeechService(),
);

class SpeechToTextManualProductSpeechService
    implements ManualProductSpeechService {
  SpeechToTextManualProductSpeechService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  ValueChanged<ManualProductSpeechRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<ManualProductSpeechFailure>? _onError;
  bool _isInitialized = false;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<ManualProductSpeechFailure?> startListening({
    required ValueChanged<ManualProductSpeechRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<ManualProductSpeechFailure> onError,
  }) async {
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
    _onError = onError;

    final initFailure = await _ensureInitialized();
    if (initFailure != null) {
      return initFailure;
    }

    try {
      await _speechToText.listen(
        onResult: _handleResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.search,
        ),
      );
    } on PlatformException catch (error, stackTrace) {
      log(
        'Failed to start speech recognition.',
        name: _manualProductSpeechServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return ManualProductSpeechFailure.error;
    } catch (error, stackTrace) {
      log(
        'Unexpected speech recognition startup failure.',
        name: _manualProductSpeechServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return ManualProductSpeechFailure.error;
    }

    _onListeningStateChanged?.call(_speechToText.isListening);
    return null;
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
    _onListeningStateChanged?.call(false);
  }

  @override
  Future<void> cancelListening() async {
    await _speechToText.cancel();
    _onListeningStateChanged?.call(false);
  }

  Future<ManualProductSpeechFailure?> _ensureInitialized() async {
    if (_isInitialized) {
      return null;
    }

    try {
      final initialized = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: false,
      );
      _isInitialized = initialized;
      if (initialized) {
        return null;
      }

      return await _permissionOrAvailabilityFailure();
    } on MissingPluginException catch (error, stackTrace) {
      log(
        'Speech recognition plugin is unavailable on this platform.',
        name: _manualProductSpeechServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return ManualProductSpeechFailure.unavailable;
    } on PlatformException catch (error, stackTrace) {
      log(
        'Failed to initialize speech recognition.',
        name: _manualProductSpeechServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return _mapPlatformFailure(error);
    } catch (error, stackTrace) {
      log(
        'Unexpected speech recognition initialization failure.',
        name: _manualProductSpeechServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return ManualProductSpeechFailure.error;
    }
  }

  Future<ManualProductSpeechFailure> _permissionOrAvailabilityFailure() async {
    try {
      final hasPermission = await _speechToText.hasPermission;
      return hasPermission
          ? ManualProductSpeechFailure.unavailable
          : ManualProductSpeechFailure.permissionDenied;
    } catch (_) {
      return ManualProductSpeechFailure.unavailable;
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords.trim();
    if (transcript.isEmpty) {
      return;
    }

    _onResult?.call(
      ManualProductSpeechRecognition(
        transcript: transcript,
        isFinal: result.finalResult,
      ),
    );
  }

  void _handleStatus(String status) {
    _onListeningStateChanged?.call(status == SpeechToText.listeningStatus);
  }

  void _handleError(SpeechRecognitionError error) {
    _onListeningStateChanged?.call(false);

    if (!_isInitialized || !error.permanent) {
      return;
    }

    final failure = _mapErrorMessage(error.errorMsg);
    if (failure == ManualProductSpeechFailure.unavailable) {
      log(
        'Speech recognition became unavailable.',
        name: _manualProductSpeechServiceLogName,
        error: error,
      );
    } else if (failure == ManualProductSpeechFailure.error) {
      log(
        'Speech recognition failed during listening.',
        name: _manualProductSpeechServiceLogName,
        error: error,
      );
    }
    _onError?.call(failure);
  }

  ManualProductSpeechFailure _mapPlatformFailure(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('permission') || message.contains('permission')) {
      return ManualProductSpeechFailure.permissionDenied;
    }
    return ManualProductSpeechFailure.error;
  }

  ManualProductSpeechFailure _mapErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('denied') ||
        normalized.contains('not_authorized') ||
        normalized.contains('notauthorized')) {
      return ManualProductSpeechFailure.permissionDenied;
    }
    if (normalized.contains('language_not_supported') ||
        normalized.contains('language_unavailable') ||
        normalized.contains('recognizer_disabled') ||
        normalized.contains('too_many_requests') ||
        normalized.contains('busy')) {
      return ManualProductSpeechFailure.unavailable;
    }
    return ManualProductSpeechFailure.error;
  }
}
