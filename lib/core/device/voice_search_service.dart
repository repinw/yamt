import 'dart:developer' show log;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

const _voiceSearchServiceLogName = 'VoiceSearchService';

/// Failures that can happen while starting or using voice search.
enum VoiceSearchFailure {
  /// Voice recognition is unavailable on this device or platform.
  unavailable,

  /// Microphone or speech permission was denied.
  permissionDenied,

  /// Unknown voice recognition failure.
  error,
}

/// One speech recognition update emitted to listeners.
class VoiceSearchRecognition {
  /// Creates voice recognition update.
  const VoiceSearchRecognition({
    required this.transcript,
    required this.isFinal,
  });

  /// Recognized speech transcript.
  final String transcript;

  /// Whether the recognition result is final.
  final bool isFinal;
}

/// Service contract for microphone-based voice search.
abstract class VoiceSearchService {
  /// Whether the service is currently listening.
  bool get isListening;

  /// Starts listening and streams recognition updates through callbacks.
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  });

  /// Stops active listening session.
  Future<void> stopListening();

  /// Cancels active listening session.
  Future<void> cancelListening();
}

/// Provides app voice search service implementation.
final voiceSearchServiceProvider = Provider<VoiceSearchService>(
  (ref) => SpeechToTextVoiceSearchService(),
);

/// `speech_to_text`-backed voice search service.
class SpeechToTextVoiceSearchService implements VoiceSearchService {
  /// Creates speech-to-text voice search service.
  SpeechToTextVoiceSearchService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<VoiceSearchFailure>? _onError;
  bool _isInitialized = false;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
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
          listenMode: ListenMode.search,
        ),
      );
    } on PlatformException catch (error, stackTrace) {
      log(
        'Failed to start speech recognition.',
        name: _voiceSearchServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return VoiceSearchFailure.error;
    } on Object catch (error, stackTrace) {
      log(
        'Unexpected speech recognition startup failure.',
        name: _voiceSearchServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return VoiceSearchFailure.error;
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

  Future<VoiceSearchFailure?> _ensureInitialized() async {
    if (_isInitialized) {
      return null;
    }

    try {
      final initialized = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      _isInitialized = initialized;
      if (initialized) {
        return null;
      }

      return await _permissionOrAvailabilityFailure();
    } on MissingPluginException catch (error, stackTrace) {
      log(
        'Speech recognition plugin is unavailable on this platform.',
        name: _voiceSearchServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return VoiceSearchFailure.unavailable;
    } on PlatformException catch (error, stackTrace) {
      log(
        'Failed to initialize speech recognition.',
        name: _voiceSearchServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return _mapPlatformFailure(error);
    } on Object catch (error, stackTrace) {
      log(
        'Unexpected speech recognition initialization failure.',
        name: _voiceSearchServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return VoiceSearchFailure.error;
    }
  }

  Future<VoiceSearchFailure> _permissionOrAvailabilityFailure() async {
    try {
      final hasPermission = await _speechToText.hasPermission;
      return hasPermission
          ? VoiceSearchFailure.unavailable
          : VoiceSearchFailure.permissionDenied;
    } on Object {
      return VoiceSearchFailure.unavailable;
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords.trim();
    if (transcript.isEmpty) {
      return;
    }

    _onResult?.call(
      VoiceSearchRecognition(
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
    if (failure == VoiceSearchFailure.unavailable) {
      log(
        'Speech recognition became unavailable.',
        name: _voiceSearchServiceLogName,
        error: error,
      );
    } else if (failure == VoiceSearchFailure.error) {
      log(
        'Speech recognition failed during listening.',
        name: _voiceSearchServiceLogName,
        error: error,
      );
    }
    _onError?.call(failure);
  }

  VoiceSearchFailure _mapPlatformFailure(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('permission') || message.contains('permission')) {
      return VoiceSearchFailure.permissionDenied;
    }
    return VoiceSearchFailure.error;
  }

  VoiceSearchFailure _mapErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('denied') ||
        normalized.contains('not_authorized') ||
        normalized.contains('notauthorized')) {
      return VoiceSearchFailure.permissionDenied;
    }
    if (normalized.contains('language_not_supported') ||
        normalized.contains('language_unavailable') ||
        normalized.contains('recognizer_disabled') ||
        normalized.contains('too_many_requests') ||
        normalized.contains('busy')) {
      return VoiceSearchFailure.unavailable;
    }
    return VoiceSearchFailure.error;
  }
}
