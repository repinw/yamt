import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/free_cooking_text_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Silence that ends one recognition while cooking: shorter than the voice
/// service's default, so rows appear soon after the cook stops speaking.
const _pause = Duration(seconds: 2);

/// How often listening restarts after silence before it stops: about a
/// minute at [_pause].
const _maxSilentRestarts = 30;

/// How long a stop shows what was heard while it waits for the final
/// result, which still counts when it comes later.
const _finalWait = Duration(seconds: 3);

/// Voice input for cooking with busy hands: once started, it keeps
/// listening across pauses until the cook taps again or stays silent for
/// about a minute. Each final recognition goes to [onSpokenText].
mixin CookingVoiceInputMixin<T extends StatefulWidget>
    on VoiceInputStateMixin<T> {
  bool _keepsListening = false;
  // After a stop, the final result for what was still being heard.
  bool _awaitsFinal = false;
  Timer? _finalTimer;
  // Completes when the final result after a stop arrives.
  Completer<void>? _finalArrived;
  int _silentRestarts = 0;

  /// What the microphone hears before it is final. Only the widgets that
  /// show it listen, so a partial result does not rebuild the page.
  final pendingSpeech = ValueNotifier<String?>(null);

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
    _finalTimer?.cancel();
    pendingSpeech.value = null;
    _silentRestarts = 0;
    await _listen();
  }

  /// Stops listening for good. What was still being heard stays shown
  /// until the final result that stopping sends a moment later goes to
  /// [onSpokenText]; the half-heard text goes away after a while if the
  /// final result is late, and the final still counts when it comes.
  Future<void> stopListening() async {
    if (!isListening) {
      return;
    }
    _keepsListening = false;
    _awaitsFinal = true;
    _finalTimer?.cancel();
    _finalTimer = Timer(_finalWait, () {
      if (mounted) {
        pendingSpeech.value = null;
      }
    });
    await voiceService.stopListening();
  }

  /// Stops listening for good, such as before cooking: what was still being
  /// heard goes to [onSpokenText] now, and no final result follows. Right
  /// after a stop, it first waits a moment for that stop's final result,
  /// else it takes what the stop showed.
  Future<void> finishListening() async {
    _keepsListening = false;
    final shown = pendingSpeech.value;
    if (_awaitsFinal && shown != null) {
      final arrived = _finalArrived = Completer<void>();
      await arrived.future.timeout(_finalWait, onTimeout: () {});
      if (!mounted) {
        return;
      }
      _finalArrived = null;
      if (!arrived.isCompleted) {
        pendingSpeech.value = shown;
      }
    }
    _takePending();
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

  @override
  void dispose() {
    _finalTimer?.cancel();
    pendingSpeech.dispose();
    super.dispose();
  }

  // Takes what is still heard as final, and no final result after it.
  void _takePending() {
    _awaitsFinal = false;
    _finalTimer?.cancel();
    final pending = pendingSpeech.value;
    if (pending != null && mounted) {
      pendingSpeech.value = null;
      onSpokenText(pending);
    }
  }

  Future<void> _listen() async {
    setState(() => isStartingVoiceSearch = true);
    final failure = await startVoiceInput(
      voiceService,
      onResult: _onSpeech,
      pauseFor: _pause,
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
      handleVoiceError(failure);
    }
  }

  @override
  void handleVoiceListeningChanged({required bool isListening}) {
    // While starting, _listen sets the flags once the start returns; a
    // restart now would overlap the session that is starting.
    if (isStartingVoiceSearch) {
      return;
    }
    super.handleVoiceListeningChanged(isListening: isListening);
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
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

  @override
  void handleVoiceError(VoiceSearchFailure failure) {
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
    _keepsListening = false;
    _awaitsFinal = false;
    _finalTimer?.cancel();
    pendingSpeech.value = null;
    super.handleVoiceError(failure);
  }

  void _onSpeech(VoiceSearchRecognition result) {
    if (isDisposingVoiceInput ||
        !mounted ||
        !(_keepsListening || _awaitsFinal) ||
        // Finishing pauses voice input but still waits for its final.
        (pausesVoiceInput && _finalArrived == null)) {
      return;
    }
    if (!result.isFinal) {
      pendingSpeech.value = result.transcript;
      return;
    }
    _awaitsFinal = false;
    _finalTimer?.cancel();
    _silentRestarts = 0;
    pendingSpeech.value = null;
    onSpokenText(result.transcript);
    if (_finalArrived case final arrived? when !arrived.isCompleted) {
      arrived.complete();
    }
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
