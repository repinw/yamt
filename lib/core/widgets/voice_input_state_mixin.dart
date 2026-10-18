import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';

/// Listening flags and speech callbacks shared by widgets with voice input.
mixin VoiceInputStateMixin<T extends StatefulWidget> on State<T> {
  /// Whether the microphone is listening.
  bool isListeningToSpeech = false;

  /// Whether a voice session is starting.
  bool isStartingVoiceSearch = false;

  /// Whether the widget is being disposed.
  bool isDisposingVoiceInput = false;

  /// Shows a failed voice session to the user.
  void showVoiceInputFailure(VoiceSearchFailure failure);

  /// Starts [service] and keeps the flags in sync with it.
  Future<VoiceSearchFailure?> startVoiceInput(
    VoiceSearchService service, {
    required ValueChanged<VoiceSearchRecognition> onResult,
  }) {
    return service.startListening(
      onResult: onResult,
      onListeningStateChanged: (isListening) =>
          handleVoiceListeningChanged(isListening: isListening),
      onError: handleVoiceError,
    );
  }

  /// Keeps the flags in sync when listening starts or ends.
  @protected
  @mustCallSuper
  void handleVoiceListeningChanged({required bool isListening}) {
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
    if (isListeningToSpeech == isListening &&
        (isListening || !isStartingVoiceSearch)) {
      return;
    }

    setState(() {
      isListeningToSpeech = isListening;
      if (!isListening) {
        isStartingVoiceSearch = false;
      }
    });
  }

  /// Clears the flags and shows [failure].
  @protected
  @mustCallSuper
  void handleVoiceError(VoiceSearchFailure failure) {
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
    if (isListeningToSpeech || isStartingVoiceSearch) {
      setState(() {
        isListeningToSpeech = false;
        isStartingVoiceSearch = false;
      });
    }
    showVoiceInputFailure(failure);
  }
}
