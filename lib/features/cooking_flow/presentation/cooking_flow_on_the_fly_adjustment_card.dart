import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_on_the_fly_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// On-the-fly cookflow note input.
class CookingFlowOnTheFlyAdjustmentCard extends ConsumerStatefulWidget {
  /// Creates on-the-fly note input.
  const new({
    required this.adjustmentController,
    required this.adjustments,
    required this.onAddPressed,
    required this.onRemovePressed,
    super.key,
  });

  /// Current note text.
  final TextEditingController adjustmentController;

  /// Added note list.
  final List<String> adjustments;

  /// Adds current note.
  final VoidCallback onAddPressed;

  /// Removes note by index.
  final void Function(int index) onRemovePressed;

  @override
  ConsumerState<CookingFlowOnTheFlyAdjustmentCard> createState() =>
      _CookingFlowOnTheFlyAdjustmentCardState();
}

class _CookingFlowOnTheFlyAdjustmentCardState
    extends ConsumerState<CookingFlowOnTheFlyAdjustmentCard> {
  late final VoiceSearchService _voiceSearchService;
  var _isListeningToSpeech = false;
  var _isStartingVoiceSearch = false;
  var _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
  }

  @override
  void dispose() {
    _isDisposing = true;
    unawaited(_voiceSearchService.cancelListening());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final recentAdjustments = widget.adjustments.length <= 2
        ? widget.adjustments
        : widget.adjustments.sublist(widget.adjustments.length - 2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const CookingFlowOnTheFlyHeader(),
            const SizedBox(height: AppSpacing.xs),
            CookingFlowOnTheFlyInputRow(
              controller: widget.adjustmentController,
              isListeningToSpeech: _isListeningToSpeech,
              onVoicePressed: _handleVoiceButtonPressed,
              onAddPressed: _handleAddPressed,
            ),
            if (widget.adjustments.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              CookingFlowOnTheFlyRecentAdjustments(
                adjustments: recentAdjustments,
                startIndex:
                    widget.adjustments.length - recentAdjustments.length,
                onRemovePressed: widget.onRemovePressed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleVoiceButtonPressed() async {
    if (_isStartingVoiceSearch) {
      return;
    }
    if (_isListeningToSpeech || _voiceSearchService.isListening) {
      await _stopVoiceSearchIfNeeded();
      return;
    }

    setState(() {
      _isStartingVoiceSearch = true;
    });

    final failure = await _voiceSearchService.startListening(
      onResult: _handleSpeechResult,
      onListeningStateChanged: _handleSpeechListeningChanged,
      onError: _handleSpeechError,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isStartingVoiceSearch = false;
      _isListeningToSpeech = failure == null;
    });

    if (failure != null) {
      _showSnackBar(_resolveSpeechErrorText(failure));
    }
  }

  void _handleAddPressed() {
    unawaited(_stopVoiceSearchIfNeeded());
    widget.onAddPressed();
  }

  Future<void> _stopVoiceSearchIfNeeded() async {
    if (!_isListeningToSpeech && !_voiceSearchService.isListening) {
      return;
    }
    await _voiceSearchService.stopListening();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListeningToSpeech = false;
      _isStartingVoiceSearch = false;
    });
  }

  void _handleSpeechResult(VoiceSearchRecognition result) {
    if (_isDisposing || !mounted) {
      return;
    }
    final transcript = result.transcript.trim();
    if (transcript.isEmpty || widget.adjustmentController.text == transcript) {
      return;
    }

    widget.adjustmentController.value = TextEditingValue(
      text: transcript,
      selection: TextSelection.collapsed(offset: transcript.length),
    );
  }

  void _handleSpeechListeningChanged(bool isListening) {
    if (_isDisposing || !mounted) {
      return;
    }
    if (_isListeningToSpeech == isListening &&
        (isListening || !_isStartingVoiceSearch)) {
      return;
    }

    setState(() {
      _isListeningToSpeech = isListening;
      if (!isListening) {
        _isStartingVoiceSearch = false;
      }
    });
  }

  void _handleSpeechError(VoiceSearchFailure failure) {
    if (_isDisposing || !mounted) {
      return;
    }
    if (_isListeningToSpeech || _isStartingVoiceSearch) {
      setState(() {
        _isListeningToSpeech = false;
        _isStartingVoiceSearch = false;
      });
    }
    _showSnackBar(_resolveSpeechErrorText(failure));
  }

  String _resolveSpeechErrorText(VoiceSearchFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    return switch (failure) {
      VoiceSearchFailure.unavailable => l10n.cookflowVoiceInputUnavailable,
      VoiceSearchFailure.permissionDenied =>
        l10n.cookflowVoiceInputPermissionDenied,
      VoiceSearchFailure.error => l10n.cookflowVoiceInputFailed,
    };
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showAppSnackBar(message, tone: AppSnackBarTone.error);
  }
}
