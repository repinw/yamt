import 'package:flutter/foundation.dart';
import 'package:yamt/core/device/voice_search_service.dart';

/// A speech service that listens until the test [say]s something.
class FakeVoiceSearchService implements VoiceSearchService {
  /// What the next start returns; `null` starts listening.
  VoiceSearchFailure? failure;

  /// How often listening started.
  int starts = 0;

  bool _listening = false;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;

  @override
  bool get isListening => _listening;

  /// Plays what the user says; [isFinal] ends the recognition.
  void say(String transcript, {bool isFinal = true}) {
    _onResult?.call(
      VoiceSearchRecognition(transcript: transcript, isFinal: isFinal),
    );
    if (isFinal) {
      _listening = false;
      _onListeningStateChanged?.call(false);
    }
  }

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
    Duration? pauseFor,
  }) async {
    starts++;
    if (failure != null) return failure;
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
    _listening = true;
    onListeningStateChanged(true);
    return null;
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    _onListeningStateChanged?.call(false);
  }

  @override
  Future<void> cancelListening() => stopListening();
}
