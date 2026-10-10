import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/free_cooking_text_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// How often listening restarts after silence before it stops: about a
/// minute at the 4 s pause of the voice service.
const _maxSilentRestarts = 15;

/// Voice input for cooking with busy hands: once started, it keeps
/// listening across pauses until the cook taps again or stays silent for
/// about a minute. Each final recognition goes to [onSpokenText].
mixin CookingVoiceInputMixin<T extends StatefulWidget>
    on VoiceInputStateMixin<T> {
  bool _keepsListening = false;
  // After a stop, the final result for what was still being heard.
  bool _awaitsFinal = false;
  int _silentRestarts = 0;

  /// What the microphone hears before it is final.
  String? pendingSpeech;

  /// The voice service, read once when the page opens.
  VoiceSearchService get voiceService;

  /// Whether speech must be ignored, such as while the meal is saving.
  bool get pausesVoiceInput;

  /// Takes what the cook said or typed.
  void onSpokenText(String text);

  /// Whether the microphone is listening or starting.
  bool get isListening => isListeningToSpeech || isStartingVoiceSearch;

  /// Starts listening, or stops it for good.
  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
      return;
    }
    _keepsListening = true;
    _awaitsFinal = false;
    _silentRestarts = 0;
    await _listen();
  }

  /// Stops listening for good. What was still being heard goes to
  /// [onSpokenText] with the final result that stopping sends a moment
  /// later, if the recognizer sends one.
  Future<void> stopListening() async {
    if (!isListening) {
      return;
    }
    _keepsListening = false;
    _awaitsFinal = true;
    await voiceService.stopListening();
    if (mounted) {
      setState(() => pendingSpeech = null);
    }
  }

  /// Stops listening for good right away, such as before cooking: what was
  /// still being heard goes to [onSpokenText] now, and no final result
  /// follows.
  Future<void> finishListening() async {
    _keepsListening = false;
    _awaitsFinal = false;
    final pending = pendingSpeech;
    if (pending != null) {
      setState(() => pendingSpeech = null);
      onSpokenText(pending);
    }
    if (isListening) {
      await voiceService.cancelListening();
    }
  }

  /// Stops listening and opens the field to type ingredients instead.
  Future<void> typeText() async {
    await stopListening();
    if (!mounted) {
      return;
    }
    final text = await FreeCookingTextSheet.show(context);
    if (text != null && mounted) {
      onSpokenText(text);
    }
  }

  /// Ends listening when the page closes.
  void cancelListening() {
    isDisposingVoiceInput = true;
    unawaited(voiceService.cancelListening());
  }

  Future<void> _listen() async {
    setState(() => isStartingVoiceSearch = true);
    final failure = await voiceService.startListening(
      onResult: _onSpeech,
      onListeningStateChanged: _onListeningChanged,
      onError: _onVoiceError,
    );
    if (!mounted) {
      // The page closed while listening was starting.
      if (failure == null) {
        unawaited(voiceService.cancelListening());
      }
      return;
    }
    // The cook stopped, or an error ended listening, while it was starting.
    final stopped = !_keepsListening;
    if (stopped && failure == null) {
      unawaited(voiceService.stopListening());
    }
    setState(() {
      isStartingVoiceSearch = false;
      isListeningToSpeech = failure == null && !stopped;
    });
    if (failure != null && !stopped) {
      _onVoiceError(failure);
    }
  }

  void _onListeningChanged(bool isListening) {
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
    setState(() => isListeningToSpeech = isListening);
    // A pause or silence ends one recognition. Listening goes on until the
    // cook taps, but stops after about a minute of silence.
    if (!isListening && _keepsListening) {
      // Not before the service reports the error that ended it, if any.
      scheduleMicrotask(_restart);
    }
  }

  void _restart() {
    if (isDisposingVoiceInput ||
        !mounted ||
        !_keepsListening ||
        pausesVoiceInput ||
        isListening ||
        _silentRestarts >= _maxSilentRestarts) {
      return;
    }
    _silentRestarts++;
    unawaited(_listen());
  }

  void _onVoiceError(VoiceSearchFailure failure) {
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
    _keepsListening = false;
    _awaitsFinal = false;
    setState(() {
      isListeningToSpeech = false;
      isStartingVoiceSearch = false;
      pendingSpeech = null;
    });
    showVoiceInputFailure(failure);
  }

  void _onSpeech(VoiceSearchRecognition result) {
    if (isDisposingVoiceInput ||
        !mounted ||
        !(_keepsListening || _awaitsFinal) ||
        pausesVoiceInput) {
      return;
    }
    if (!result.isFinal) {
      setState(() => pendingSpeech = result.transcript);
      return;
    }
    _awaitsFinal = false;
    _silentRestarts = 0;
    setState(() => pendingSpeech = null);
    onSpokenText(result.transcript);
  }

  @override
  void showVoiceInputFailure(VoiceSearchFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showAppSnackBar(switch (failure) {
      VoiceSearchFailure.unavailable => l10n.freeCookingVoiceUnavailable,
      VoiceSearchFailure.permissionDenied =>
        l10n.freeCookingVoicePermissionDenied,
      VoiceSearchFailure.error => l10n.freeCookingVoiceFailed,
    }, tone: AppSnackBarTone.error);
  }
}
