import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/domain/cook_voice_command.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_said_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_timer_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Sprechen" and "Schreiben" at the foot of "Kochen", with what was
/// heard ("Gehört: …") or typed ("Geschrieben: …"). What the cook says
/// becomes new lines, or a weight on the assigned line it names ("30 g Öl"),
/// shown below what was heard; "nein" takes back what was said last, also
/// after a switch of tab or between guide and list
/// (`KochmodusSaidController`); in the guide "weiter", "zurück" and
/// "Timer 5 Minuten" work too.
class KochmodusVoiceBar extends ConsumerStatefulWidget {
  /// Creates the bar of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of "Sprechen".
  static const speakKey = ValueKey<String>('kochmodus-voice-speak');

  /// Key of "Schreiben".
  static const typeKey = ValueKey<String>('kochmodus-voice-type');

  /// Key of "Gehört: …", or "Geschrieben: …" for what was typed.
  static const heardKey = ValueKey<String>('kochmodus-voice-heard');

  /// Key of "Öl · 30 g gewogen" under "Gehört: …" for the line [lineId].
  static ValueKey<String> weighedKey(String lineId) =>
      ValueKey<String>('kochmodus-voice-weighed-$lineId');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  @override
  ConsumerState<KochmodusVoiceBar> createState() => _KochmodusVoiceBarState();
}

class _KochmodusVoiceBarState extends ConsumerState<KochmodusVoiceBar>
    with VoiceInputStateMixin<KochmodusVoiceBar> {
  late final VoiceSearchService _voice;
  String? _heard;
  // Whether [_heard] was typed, not said.
  bool _typed = false;
  // The lines that what was heard last weighed.
  Set<String> _weighed = const {};

  bool get _listening => isListeningToSpeech || isStartingVoiceSearch;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceSearchServiceProvider);
  }

  @override
  void dispose() {
    isDisposingVoiceInput = true;
    unawaited(_voice.cancelListening());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (isStartingVoiceSearch) return;
    if (isListeningToSpeech) {
      await _voice.stopListening();
      return;
    }
    setState(() => isStartingVoiceSearch = true);
    final failure = await startVoiceInput(_voice, onResult: _onSpeech);
    if (!mounted) {
      if (failure == null) unawaited(_voice.cancelListening());
      return;
    }
    setState(() {
      isStartingVoiceSearch = false;
      isListeningToSpeech = failure == null && _voice.isListening;
    });
    if (failure != null) handleVoiceError(failure);
  }

  void _onSpeech(VoiceSearchRecognition result) {
    if (isDisposingVoiceInput || !mounted) return;
    _hear(result.transcript, typed: false);
    if (result.isFinal) unawaited(_take(result.transcript));
  }

  Future<void> _type() async {
    if (isListeningToSpeech) await _voice.stopListening();
    if (!mounted) return;
    final text = await KochmodusTypeSheet.show(context);
    if (text == null || !mounted) return;
    _hear(text, typed: true);
    await _take(text);
  }

  void _hear(String text, {required bool typed}) => setState(() {
    _heard = text;
    _typed = typed;
    _weighed = const {};
  });

  // Acts on what was said or typed.
  Future<void> _take(String said) async {
    final view = widget.view;
    final guide = view.showGuide;
    final index = view.run.guideStep;
    final localeCode = Localizations.localeOf(context).languageCode;
    switch (parseCookVoiceCommand(said)) {
      case CookVoiceAddLines(:final lines):
        for (final line in lines) {
          if (!mounted) return;
          final taken = await KochmodusActionFlow.result(
            context,
            widget.target,
            (controller) => _said.take(
              controller,
              line,
              items: view.items,
              localeCode: localeCode,
            ),
          );
          if (taken == null || !mounted) continue;
          if (taken.before != null) {
            setState(() => _weighed = {..._weighed, taken.lineId});
          }
        }
      case CookVoiceUndo():
        await _run(_said.undoLast);
      case CookVoiceNext() when guide && index < view.guide.length - 1:
        await _run((controller) => controller.guideTo(index + 1));
      case CookVoiceBack() when guide && index > 0:
        await _run((controller) => controller.guideTo(index - 1));
      case CookVoiceTimer(:final duration) when guide:
        // Its own name: the step's timer may count already.
        final label = KochmodusActionFlow.freeTimerName(
          AppLocalizations.of(context)!,
          view,
        );
        await _run((_) => _timers.startTimer(label, duration));
      case CookVoiceNext() || CookVoiceBack() || CookVoiceTimer() || null:
        // Heard, but nothing to do here; "Gehört" shows it.
        return;
    }
  }

  KochmodusSaidController get _said =>
      ref.read(kochmodusSaidControllerProvider(widget.target).notifier);

  KochmodusTimerController get _timers =>
      ref.read(kochmodusTimerControllerProvider(widget.target).notifier);

  Future<void> _run(
    Future<bool> Function(KochmodusController controller) action,
  ) async {
    if (!mounted) return;
    await KochmodusActionFlow.run(context, widget.target, action);
  }

  @override
  void showVoiceInputFailure(VoiceSearchFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showAppSnackBar(switch (failure) {
      VoiceSearchFailure.unavailable => l10n.cookingVoiceUnavailable,
      VoiceSearchFailure.permissionDenied => l10n.cookingVoicePermissionDenied,
      VoiceSearchFailure.error => l10n.cookingVoiceFailed,
    }, tone: AppSnackBarTone.error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final heard = _heard;
    final large =
        MediaQuery.textScalerOf(context).scale(1) > kochmodusLargeText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        if (heard != null)
          Text(
            _typed
                ? l10n.kochmodusVoiceTyped(heard)
                : l10n.kochmodusVoiceHeard(heard),
            key: KochmodusVoiceBar.heardKey,
            style: textTheme.bodySmall?.copyWith(color: colors.ink),
          ),
        for (final line in widget.view.lines)
          if (_weighed.contains(line.id))
            if (line.weight case CookWeightWeighed(:final grams))
              Text(
                l10n.kochmodusCookLineSub(
                  line.need?.name ?? line.text,
                  l10n.kochmodusWeightWeighed(grams),
                ),
                key: KochmodusVoiceBar.weighedKey(line.id),
                style: textTheme.bodySmall?.copyWith(color: colors.ink),
              ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                key: KochmodusVoiceBar.speakKey,
                onPressed: () => unawaited(_toggle()),
                icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(
                  _listening
                      ? l10n.kochmodusVoiceListening
                      : l10n.kochmodusVoiceSpeak,
                ),
              ),
            ),
            // At a large text "Schreiben" is an icon, so "Sprechen" keeps
            // its room.
            if (large)
              IconButton.outlined(
                key: KochmodusVoiceBar.typeKey,
                tooltip: l10n.cookingTypeAction,
                onPressed: () => unawaited(_type()),
                icon: const Icon(Icons.keyboard_outlined),
              )
            else
              OutlinedButton.icon(
                key: KochmodusVoiceBar.typeKey,
                onPressed: () => unawaited(_type()),
                icon: const Icon(Icons.keyboard_outlined),
                label: Text(l10n.cookingTypeAction),
              ),
          ],
        ),
        Text(
          widget.view.showGuide
              ? l10n.kochmodusVoiceHintGuide
              : l10n.kochmodusVoiceHintList,
          style: textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}
