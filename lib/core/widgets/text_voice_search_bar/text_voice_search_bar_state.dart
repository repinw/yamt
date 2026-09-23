import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// State for [TextVoiceSearchBar]. Public so the widget's `createState` can
/// live in its own file without exceeding the file size limit.
class TextVoiceSearchBarState extends State<TextVoiceSearchBar> {
  var _isListeningToSpeech = false;
  var _isStartingVoiceSearch = false;
  var _didTriggerInitialVoiceSearch = false;
  var _isDisposing = false;

  bool get _usesInternalVoiceSearch {
    return widget.voiceSearchService != null &&
        widget.onVoiceSearchPressed == null;
  }

  @override
  void initState() {
    super.initState();
    _attachVoiceSearchController();
    _maybeStartVoiceSearchOnMount();
  }

  @override
  void didUpdateWidget(covariant TextVoiceSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.voiceSearchController,
      widget.voiceSearchController,
    )) {
      oldWidget.voiceSearchController?.detach();
      _attachVoiceSearchController();
    }
    if (oldWidget.enabled && !widget.enabled) {
      unawaited(stopVoiceSearchIfNeeded());
    }
    _maybeStartVoiceSearchOnMount();
  }

  @override
  void dispose() {
    _isDisposing = true;
    widget.voiceSearchController?.detach();
    final voiceSearchService = widget.voiceSearchService;
    if (voiceSearchService != null) {
      unawaited(voiceSearchService.cancelListening());
    }
    super.dispose();
  }

  /// Stops voice search if a session is active.
  Future<void> stopVoiceSearchIfNeeded() async {
    final voiceSearchService = widget.voiceSearchService;
    if (voiceSearchService == null) {
      return;
    }
    if (!_isListeningToSpeech && !voiceSearchService.isListening) {
      return;
    }

    await voiceSearchService.stopListening();
    if (!mounted) {
      return;
    }

    setState(() {
      _isListeningToSpeech = false;
      _isStartingVoiceSearch = false;
    });
  }

  /// Cancels any active voice search session.
  Future<void> cancelVoiceSearch() async {
    final voiceSearchService = widget.voiceSearchService;
    if (voiceSearchService == null) {
      return;
    }
    await voiceSearchService.cancelListening();
    if (!mounted) {
      return;
    }

    setState(() {
      _isListeningToSpeech = false;
      _isStartingVoiceSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextVoiceSearchField(
            controller: widget.controller,
            label: widget.label,
            hintText: widget.hintText,
            fieldKey: widget.fieldKey,
            clearButtonKey: widget.clearButtonKey,
            focusNode: widget.focusNode,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            isSearching: widget.isSearching,
            prefixIcon: widget.prefixIcon,
            useCompactSurface: widget.useCompactSurface,
            clearTooltip: widget.clearTooltip,
            voiceButtonKey: widget.voiceButtonKey,
            isVoiceListening: _usesInternalVoiceSearch && _isListeningToSpeech,
            voiceTooltip: _resolveVoiceTooltip(context),
            onVoiceButtonPressed: _handleVoiceButtonPressed,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onClearPressed: _handleClearPressed,
          ),
        ),
        for (final action in widget.trailingActions) ...[
          const SizedBox(width: AppSpacing.sm),
          action,
        ],
      ],
    );
  }

  Future<void> _handleVoiceButtonPressed() async {
    if (!_usesInternalVoiceSearch) {
      widget.onVoiceSearchPressed?.call();
      return;
    }

    if (_isStartingVoiceSearch) {
      return;
    }
    if (_isListeningToSpeech) {
      await stopVoiceSearchIfNeeded();
      return;
    }

    final voiceSearchService = widget.voiceSearchService;
    if (voiceSearchService == null) {
      return;
    }

    setState(() {
      _isStartingVoiceSearch = true;
    });

    final failure = await voiceSearchService.startListening(
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
      _showSnackBar(_resolveSpeechErrorText(context, failure));
    }
  }

  void _handleClearPressed() {
    final customHandler = widget.onClearPressed;
    if (customHandler != null) {
      customHandler();
      unawaited(stopVoiceSearchIfNeeded());
      return;
    }
    widget.controller.clear();
    widget.onChanged?.call('');
    unawaited(stopVoiceSearchIfNeeded());
  }

  void _handleSpeechResult(VoiceSearchRecognition result) {
    if (_isDisposing || !mounted) {
      return;
    }
    if (widget.controller.text == result.transcript) {
      return;
    }

    widget.controller.value = TextEditingValue(
      text: result.transcript,
      selection: TextSelection.collapsed(offset: result.transcript.length),
    );
    widget.onChanged?.call(result.transcript);
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
    _showSnackBar(_resolveSpeechErrorText(context, failure));
  }

  void _maybeStartVoiceSearchOnMount() {
    if (_didTriggerInitialVoiceSearch ||
        !widget.startVoiceSearchOnMount ||
        !_usesInternalVoiceSearch ||
        !widget.enabled) {
      return;
    }

    _didTriggerInitialVoiceSearch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_handleVoiceButtonPressed());
    });
  }

  String _resolveVoiceTooltip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _usesInternalVoiceSearch && _isListeningToSpeech
        ? l10n.inventoryManualAddVoiceSearchStopTooltip
        : l10n.inventoryManualAddVoiceSearchStartTooltip;
  }

  String _resolveSpeechErrorText(
    BuildContext context,
    VoiceSearchFailure failure,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch (failure) {
      VoiceSearchFailure.unavailable =>
        l10n.inventoryManualAddVoiceSearchUnavailable,
      VoiceSearchFailure.permissionDenied =>
        l10n.inventoryManualAddVoiceSearchPermissionDenied,
      VoiceSearchFailure.error => l10n.inventoryManualAddVoiceSearchFailed,
    };
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showAppSnackBar(message, tone: AppSnackBarTone.error);
  }

  void _attachVoiceSearchController() {
    widget.voiceSearchController?.attach(
      stopVoiceSearchIfNeeded: stopVoiceSearchIfNeeded,
      cancelVoiceSearch: cancelVoiceSearch,
    );
  }
}
