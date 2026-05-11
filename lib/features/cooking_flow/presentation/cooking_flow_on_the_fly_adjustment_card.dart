import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// On-the-fly cookflow note input.
class CookingFlowOnTheFlyAdjustmentCard extends ConsumerStatefulWidget {
  /// Creates on-the-fly note input.
  const CookingFlowOnTheFlyAdjustmentCard({
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
    final l10n = AppLocalizations.of(context)!;
    final recentAdjustments = widget.adjustments.length <= 2
        ? widget.adjustments
        : widget.adjustments.sublist(widget.adjustments.length - 2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF263147),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
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
            _CookingFlowOnTheFlyHeader(l10n: l10n),
            const SizedBox(height: AppSpacing.sm),
            _CookingFlowOnTheFlyInputRow(
              controller: widget.adjustmentController,
              isListeningToSpeech: _isListeningToSpeech,
              onVoicePressed: _handleVoiceButtonPressed,
              onAddPressed: _handleAddPressed,
            ),
            if (widget.adjustments.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _CookingFlowOnTheFlyRecentAdjustments(
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
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CookingFlowOnTheFlyHeader extends StatelessWidget {
  const _CookingFlowOnTheFlyHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.add, color: AppSeedColors.orange, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.cookflowOnTheFlyTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _CookingFlowOnTheFlyInputRow extends StatelessWidget {
  const _CookingFlowOnTheFlyInputRow({
    required this.controller,
    required this.isListeningToSpeech,
    required this.onVoicePressed,
    required this.onAddPressed,
  });

  final TextEditingController controller;
  final bool isListeningToSpeech;
  final VoidCallback onVoicePressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            key: const Key('cookflow_on_the_fly_field'),
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.cookflowOnTheFlyHint,
              hintStyle: const TextStyle(color: Color(0xFF9EACC6)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF39455D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _CookingFlowVoiceInputButton(
          isListeningToSpeech: isListeningToSpeech,
          onPressed: onVoicePressed,
        ),
        const SizedBox(width: AppSpacing.sm),
        CookingFlowActionIconButton(
          key: const Key('cookflow_on_the_fly_add_button'),
          icon: Icons.check_circle_outline_rounded,
          onPressed: onAddPressed,
        ),
      ],
    );
  }
}

class _CookingFlowVoiceInputButton extends StatelessWidget {
  const _CookingFlowVoiceInputButton({
    required this.isListeningToSpeech,
    required this.onPressed,
  });

  final bool isListeningToSpeech;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox.square(
      dimension: 48,
      child: IconButton.filledTonal(
        key: const Key('cookflow_on_the_fly_voice_button'),
        onPressed: onPressed,
        tooltip: isListeningToSpeech
            ? l10n.cookflowVoiceInputStopTooltip
            : l10n.cookflowVoiceInputStartTooltip,
        style: IconButton.styleFrom(
          backgroundColor: isListeningToSpeech
              ? AppSeedColors.orange
              : const Color(0xFF39455D),
          foregroundColor: Colors.white,
        ),
        icon: Icon(isListeningToSpeech ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}

class _CookingFlowOnTheFlyRecentAdjustments extends StatelessWidget {
  const _CookingFlowOnTheFlyRecentAdjustments({
    required this.adjustments,
    required this.startIndex,
    required this.onRemovePressed,
  });

  final List<String> adjustments;
  final int startIndex;
  final void Function(int index) onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 56),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            for (var index = 0; index < adjustments.length; index++) ...[
              _CookingFlowOnTheFlyAdjustmentChip(
                adjustment: adjustments[index],
                onRemovePressed: () => onRemovePressed(startIndex + index),
              ),
              if (index != adjustments.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _CookingFlowOnTheFlyAdjustmentChip extends StatelessWidget {
  const _CookingFlowOnTheFlyAdjustmentChip({
    required this.adjustment,
    required this.onRemovePressed,
  });

  final String adjustment;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF313D54),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppSeedColors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              adjustment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          SizedBox.square(
            dimension: 32,
            child: IconButton(
              key: const Key('cookflow_on_the_fly_remove_button'),
              onPressed: onRemovePressed,
              tooltip: l10n.cookflowOnTheFlyRemoveTooltip,
              iconSize: 16,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              color: const Color(0xFFCAD3E4),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
