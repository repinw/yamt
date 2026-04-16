import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:yamt/core/device/voice_search_service.dart';

class _FakeSpeechToText extends SpeechToText {
  _FakeSpeechToText() : super.withMethodChannel();

  Object? initializeThrowable;
  Object? listenThrowable;
  bool initializeResult = true;
  bool hasPermissionResult = true;
  bool _isListening = false;
  SpeechErrorListener? _errorListener;
  SpeechStatusListener? _statusListener;
  SpeechResultListener? _resultListener;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> get hasPermission async => hasPermissionResult;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    _errorListener = onError;
    _statusListener = onStatus;
    final throwable = initializeThrowable;
    if (throwable != null) {
      Error.throwWithStackTrace(throwable, StackTrace.empty);
    }
    return initializeResult;
  }

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    _resultListener = onResult;
    final throwable = listenThrowable;
    if (throwable != null) {
      Error.throwWithStackTrace(throwable, StackTrace.empty);
    }
    _isListening = true;
    _statusListener?.call(SpeechToText.listeningStatus);
  }

  @override
  Future<void> stop() async {
    _isListening = false;
    _statusListener?.call(SpeechToText.notListeningStatus);
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
    _statusListener?.call(SpeechToText.notListeningStatus);
  }

  void emitError(String message, {bool permanent = true}) {
    _isListening = false;
    _errorListener?.call(SpeechRecognitionError(message, permanent));
  }

  void emitResult(String transcript, {bool isFinal = false}) {
    _resultListener?.call(
      SpeechRecognitionResult(<SpeechRecognitionWords>[
        SpeechRecognitionWords(transcript, null, -1),
      ], isFinal),
    );
  }
}

void main() {
  test('startListening reports listening state and recognized words', () async {
    final speechToText = _FakeSpeechToText();
    final service = SpeechToTextVoiceSearchService(speechToText: speechToText);
    final listeningStates = <bool>[];
    VoiceSearchRecognition? recognition;

    final failure = await service.startListening(
      onResult: (value) {
        recognition = value;
      },
      onListeningStateChanged: listeningStates.add,
      onError: (_) {},
    );

    speechToText.emitResult('Hafermilch', isFinal: true);

    expect(failure, isNull);
    expect(service.isListening, isTrue);
    expect(listeningStates, contains(true));
    expect(recognition, isNotNull);
    expect(recognition!.transcript, 'Hafermilch');
    expect(recognition!.isFinal, isTrue);
  });

  test('returns unavailable when speech plugin is missing', () async {
    final speechToText = _FakeSpeechToText()
      ..initializeThrowable = MissingPluginException('missing');
    final service = SpeechToTextVoiceSearchService(speechToText: speechToText);

    final failure = await service.startListening(
      onResult: (_) {},
      onListeningStateChanged: (_) {},
      onError: (_) {},
    );

    expect(failure, VoiceSearchFailure.unavailable);
  });

  test(
    'returns permissionDenied when initialization has no permission',
    () async {
      final speechToText = _FakeSpeechToText()
        ..initializeResult = false
        ..hasPermissionResult = false;
      final service = SpeechToTextVoiceSearchService(
        speechToText: speechToText,
      );

      final failure = await service.startListening(
        onResult: (_) {},
        onListeningStateChanged: (_) {},
        onError: (_) {},
      );

      expect(failure, VoiceSearchFailure.permissionDenied);
    },
  );

  test('maps not_authorized recognition errors to permissionDenied', () async {
    final speechToText = _FakeSpeechToText();
    final service = SpeechToTextVoiceSearchService(speechToText: speechToText);
    final failures = <VoiceSearchFailure>[];

    final startFailure = await service.startListening(
      onResult: (_) {},
      onListeningStateChanged: (_) {},
      onError: failures.add,
    );

    speechToText.emitError('not_authorized');

    expect(startFailure, isNull);
    expect(failures, <VoiceSearchFailure>[VoiceSearchFailure.permissionDenied]);
  });
}
