import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/product_search/data/'
    'manual_product_speech_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared search field with an optional built-in voice search button.
class TextVoiceSearchBar extends StatefulWidget {
  const TextVoiceSearchBar({
    super.key,
    required this.controller,
    required this.label,
    required this.fieldKey,
    this.voiceButtonKey,
    this.clearButtonKey,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.isSearching = false,
    this.startVoiceSearchOnMount = false,
    this.onTap,
    this.onChanged,
    this.speechService,
    this.onVoiceSearchPressed,
    this.trailingActions = const <Widget>[],
  });

  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final Key? voiceButtonKey;
  final Key? clearButtonKey;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final bool isSearching;
  final bool startVoiceSearchOnMount;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ManualProductSpeechService? speechService;
  final VoidCallback? onVoiceSearchPressed;
  final List<Widget> trailingActions;

  @override
  State<TextVoiceSearchBar> createState() => TextVoiceSearchBarState();
}

/// State access for stopping or cancelling ongoing voice input externally.
class TextVoiceSearchBarState extends State<TextVoiceSearchBar> {
  var _isListeningToSpeech = false;
  var _isStartingVoiceSearch = false;
  var _didTriggerInitialVoiceSearch = false;
  var _isDisposing = false;

  bool get _usesInternalVoiceSearch {
    return widget.speechService != null && widget.onVoiceSearchPressed == null;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _maybeStartVoiceSearchOnMount();
  }

  @override
  void didUpdateWidget(covariant TextVoiceSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.enabled && !widget.enabled) {
      unawaited(stopVoiceSearchIfNeeded());
    }
    _maybeStartVoiceSearchOnMount();
  }

  @override
  void dispose() {
    _isDisposing = true;
    widget.controller.removeListener(_handleControllerChanged);
    final speechService = widget.speechService;
    if (speechService != null) {
      unawaited(speechService.cancelListening());
    }
    super.dispose();
  }

  /// Stops an active voice session while keeping the recognized query.
  Future<void> stopVoiceSearchIfNeeded() async {
    final speechService = widget.speechService;
    if (speechService == null) {
      return;
    }
    if (!_isListeningToSpeech && !speechService.isListening) {
      return;
    }

    await speechService.stopListening();
    if (!mounted) {
      return;
    }

    setState(() {
      _isListeningToSpeech = false;
      _isStartingVoiceSearch = false;
    });
  }

  /// Cancels an active voice session and resets the microphone state.
  Future<void> cancelVoiceSearch() async {
    final speechService = widget.speechService;
    if (speechService == null) {
      return;
    }
    await speechService.cancelListening();
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
    final trailingIcons = <Widget>[
      if (widget.isSearching)
        const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      if (widget.controller.text.trim().isNotEmpty)
        IconButton(
          key: widget.clearButtonKey,
          onPressed: widget.enabled ? _handleClearPressed : null,
          tooltip: AppLocalizations.of(context)!.inventorySearchClearAction,
          icon: const Icon(Icons.cleaning_services_outlined),
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            keyboardType: TextInputType.text,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: trailingIcons.isEmpty
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: trailingIcons,
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 56,
          width: 56,
          child: IconButton.outlined(
            key: widget.voiceButtonKey,
            onPressed: widget.enabled ? _handleVoiceButtonPressed : null,
            tooltip: _resolveVoiceTooltip(context),
            icon: Icon(
              _usesInternalVoiceSearch && _isListeningToSpeech
                  ? Icons.mic
                  : Icons.mic_none,
              color: _usesInternalVoiceSearch && _isListeningToSpeech
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
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

    final speechService = widget.speechService;
    if (speechService == null) {
      return;
    }

    setState(() {
      _isStartingVoiceSearch = true;
    });

    final failure = await speechService.startListening(
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
    widget.controller.clear();
    widget.onChanged?.call('');
    unawaited(stopVoiceSearchIfNeeded());
  }

  void _handleControllerChanged() {
    if (_isDisposing || !mounted) {
      return;
    }
    setState(() {});
  }

  void _handleSpeechResult(ManualProductSpeechRecognition result) {
    if (_isDisposing || !mounted) {
      return;
    }
    if (widget.controller.text == result.transcript) {
      return;
    }

    widget.controller.value = TextEditingValue(
      text: result.transcript,
      selection: TextSelection.collapsed(offset: result.transcript.length),
      composing: TextRange.empty,
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

  void _handleSpeechError(ManualProductSpeechFailure failure) {
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
    ManualProductSpeechFailure failure,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch (failure) {
      ManualProductSpeechFailure.unavailable =>
        l10n.inventoryManualAddVoiceSearchUnavailable,
      ManualProductSpeechFailure.permissionDenied =>
        l10n.inventoryManualAddVoiceSearchPermissionDenied,
      ManualProductSpeechFailure.error =>
        l10n.inventoryManualAddVoiceSearchFailed,
    };
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
