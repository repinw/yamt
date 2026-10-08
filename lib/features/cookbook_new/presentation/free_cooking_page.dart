import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'free_cooking_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_discard_dialog.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_row_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_text_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_voice_zone.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Frei kochen": a meal without a recipe. The cook says or types the
/// ingredients while cooking, sees which ones the Vorrat holds, and "Kochen"
/// saves the meal in the Vorrat with the missing rows left open, then opens
/// the "Gekocht" step.
class FreeCookingPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const new({super.key});

  /// Key of the voice zone.
  static const voiceZoneKey = ValueKey<String>('free-cooking-voice');

  /// Key of the retry button after the Vorrat failed to load.
  static const retryKey = ValueKey<String>('free-cooking-retry');

  @override
  ConsumerState<FreeCookingPage> createState() => _FreeCookingPageState();
}

/// How often listening restarts after silence before it stops: about a
/// minute at the 4 s pause of the voice service.
const _maxSilentRestarts = 15;

class _FreeCookingPageState extends ConsumerState<FreeCookingPage>
    with VoiceInputStateMixin<FreeCookingPage> {
  late final VoiceSearchService _voice;
  late final ScreenWakeLock _wakeLock;
  final _nameController = TextEditingController();
  String? _pendingText;
  bool _keepsListening = false;
  bool _isCooking = false;
  int _silentRestarts = 0;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceSearchServiceProvider);
    _wakeLock = ref.read(screenWakeLockProvider)..acquire();
  }

  @override
  void dispose() {
    isDisposingVoiceInput = true;
    unawaited(_voice.cancelListening());
    _nameController.dispose();
    _wakeLock.release();
    super.dispose();
  }

  bool get _isListening => isListeningToSpeech || isStartingVoiceSearch;

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _stopVoice();
      return;
    }
    _keepsListening = true;
    _silentRestarts = 0;
    await _listen();
  }

  /// Stops listening for good and returns what was still being heard.
  Future<String?> _stopVoice() async {
    _keepsListening = false;
    final pending = _pendingText;
    await _voice.stopListening();
    if (mounted) {
      setState(() => _pendingText = null);
    }
    return pending;
  }

  Future<void> _listen() async {
    setState(() => isStartingVoiceSearch = true);
    final failure = await _voice.startListening(
      onResult: _onSpeech,
      onListeningStateChanged: _onListeningChanged,
      onError: _onVoiceError,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      isStartingVoiceSearch = false;
      isListeningToSpeech = failure == null;
    });
    if (failure != null) {
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
    if (!isListening &&
        _keepsListening &&
        !_isCooking &&
        !isStartingVoiceSearch &&
        _silentRestarts < _maxSilentRestarts) {
      _silentRestarts++;
      unawaited(_listen());
    }
  }

  void _onVoiceError(VoiceSearchFailure failure) {
    if (isDisposingVoiceInput || !mounted) {
      return;
    }
    _keepsListening = false;
    setState(() {
      isListeningToSpeech = false;
      isStartingVoiceSearch = false;
    });
    showVoiceInputFailure(failure);
  }

  void _onSpeech(VoiceSearchRecognition result) {
    if (isDisposingVoiceInput || !mounted || _isCooking) {
      return;
    }
    if (!result.isFinal) {
      setState(() => _pendingText = result.transcript);
      return;
    }
    _silentRestarts = 0;
    setState(() => _pendingText = null);
    _addText(result.transcript);
  }

  void _addText(String text) {
    ref.read(freeCookingControllerProvider.notifier).addText(text);
  }

  Future<void> _type() async {
    if (_isListening) {
      await _toggleVoice();
    }
    if (!mounted) {
      return;
    }
    final text = await FreeCookingTextSheet.show(context);
    if (text != null && mounted) {
      _addText(text);
    }
  }

  Future<void> _cook() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final typedName = _nameController.text.trim();
    final name = typedName.isEmpty ? l10n.freeCookingDefaultName : typedName;
    setState(() => _isCooking = true);
    // What the cook is still saying belongs to the meal.
    final pending = await _stopVoice();
    if (!mounted) {
      return;
    }
    if (pending != null) {
      _addText(pending);
    }
    final rows = ref.read(freeCookingRowsProvider(l10n.localeName)).value;
    final mealId = rows == null || rows.isEmpty
        ? null
        : await ref
              .read(freeCookingControllerProvider.notifier)
              .cook(name: name, rows: rows);
    if (!mounted) {
      return;
    }
    setState(() => _isCooking = false);
    if (mealId == null) {
      messenger.showAppSnackBar(
        l10n.freeCookingSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    // Straight on to the "Gekocht" step; closing it leaves the meal in the pot.
    context.pushReplacement(AppRoutes.homeCookedMealPath(mealId));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final draft = ref.watch(freeCookingControllerProvider);
    final rowsAsync = ref.watch(freeCookingRowsProvider(l10n.localeName));
    final rows = rowsAsync.value ?? const <FreeCookingRow>[];
    final isBusy = draft.isCooking || _isCooking;
    final canCook = !isBusy && !rowsAsync.hasError && rows.isNotEmpty;

    return PopScope(
      canPop: draft.rows.isEmpty && !isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isBusy) {
          unawaited(_confirmDiscard());
        }
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        // The name field sits at the top, so the keyboard may cover the
        // voice zone and the actions instead of squeezing them.
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FreeCookingHeader(nameController: _nameController, rows: rows),
              Expanded(
                child: rowsAsync.when(
                  data: (rows) => FreeCookingRowList(
                    rows: rows,
                    pendingText: _pendingText,
                    onRemove: (index) => ref
                        .read(freeCookingControllerProvider.notifier)
                        .removeRow(index),
                  ),
                  loading: () => const AppLoadingView(),
                  error: (_, _) => AppErrorRetryView(
                    retryButtonKey: FreeCookingPage.retryKey,
                    message: l10n.freeCookingStockLoadFailed,
                    retryLabel: l10n.inventoryRetryAction,
                    onRetry: () => ref
                        .read(freeCookingControllerProvider.notifier)
                        .retryStock(),
                  ),
                ),
              ),
              FreeCookingVoiceZone(
                key: FreeCookingPage.voiceZoneKey,
                isListening: _isListening,
                onPressed: isBusy ? null : () => unawaited(_toggleVoice()),
              ),
              FreeCookingActions(
                isCooking: isBusy,
                onType: () => unawaited(_type()),
                onCook: canCook ? () => unawaited(_cook()) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    // A back gesture opens the dialog without a tap outside the name, which
    // would otherwise take the focus back when the dialog closes.
    FocusManager.instance.primaryFocus?.unfocus();
    final discard = await showFreeCookingDiscardDialog(context);
    if (discard && mounted) {
      context.pop();
    }
  }
}
