import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _textVoiceSearchMaxLines = 3;
final _textVoiceSearchInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(
    RegExp(r'[\r\n]+'),
    replacementString: ' ',
  ),
];

/// Controller for interacting with [TextVoiceSearchBar] without a [GlobalKey].
class TextVoiceSearchController {
  Future<void> Function()? _stopVoiceSearchIfNeeded;
  Future<void> Function()? _cancelVoiceSearch;

  /// Stops voice search if a session is active.
  Future<void> stopVoiceSearchIfNeeded() {
    return _stopVoiceSearchIfNeeded?.call() ?? Future<void>.value();
  }

  /// Cancels any active voice search session.
  Future<void> cancelVoiceSearch() {
    return _cancelVoiceSearch?.call() ?? Future<void>.value();
  }

  /// Releases callbacks and cancels any active voice search.
  void dispose() {
    unawaited(cancelVoiceSearch());
    _stopVoiceSearchIfNeeded = null;
    _cancelVoiceSearch = null;
  }

  void _attach({
    required Future<void> Function() stopVoiceSearchIfNeeded,
    required Future<void> Function() cancelVoiceSearch,
  }) {
    _stopVoiceSearchIfNeeded = stopVoiceSearchIfNeeded;
    _cancelVoiceSearch = cancelVoiceSearch;
  }

  void _detach() {
    _stopVoiceSearchIfNeeded = null;
    _cancelVoiceSearch = null;
  }
}

/// Shared search field with an optional built-in voice search button.
class TextVoiceSearchBar extends StatefulWidget {
  /// Creates shared text search bar with optional voice search.
  const TextVoiceSearchBar({
    required this.controller,
    required this.label,
    required this.fieldKey,
    super.key,
    this.voiceButtonKey,
    this.clearButtonKey,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.isSearching = false,
    this.startVoiceSearchOnMount = false,
    this.onTap,
    this.onChanged,
    this.voiceSearchService,
    this.voiceSearchController,
    this.onVoiceSearchPressed,
    this.trailingActions = const <Widget>[],
    this.hintText,
    this.prefixIcon,
  });

  /// Controller that holds current search text.
  final TextEditingController controller;

  /// Localized field label.
  final String label;

  /// Widget key for the text field.
  final Key fieldKey;

  /// Optional key for the voice button.
  final Key? voiceButtonKey;

  /// Optional key for the clear button.
  final Key? clearButtonKey;

  /// Whether text field should be read-only.
  final bool readOnly;

  /// Whether text field should autofocus.
  final bool autofocus;

  /// Whether all controls are enabled.
  final bool enabled;

  /// Whether a search request is currently in progress.
  final bool isSearching;

  /// Whether voice search should auto-start after first frame.
  final bool startVoiceSearchOnMount;

  /// Optional tap callback for the text field.
  final VoidCallback? onTap;

  /// Optional change callback for the text field.
  final ValueChanged<String>? onChanged;

  /// Optional internal voice search service implementation.
  final VoiceSearchService? voiceSearchService;

  /// Optional controller for external coordination.
  final TextVoiceSearchController? voiceSearchController;

  /// Optional external voice button handler.
  final VoidCallback? onVoiceSearchPressed;

  /// Extra trailing actions rendered after the voice button.
  final List<Widget> trailingActions;

  /// Optional hint text shown inside the field instead of a floating label.
  final String? hintText;

  /// Optional custom prefix icon for field.
  final Widget? prefixIcon;

  @override
  State<TextVoiceSearchBar> createState() => _TextVoiceSearchBarState();
}

class _TextVoiceSearchBarState extends State<TextVoiceSearchBar> {
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
      oldWidget.voiceSearchController?._detach();
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
    widget.voiceSearchController?._detach();
    final voiceSearchService = widget.voiceSearchService;
    if (voiceSearchService != null) {
      unawaited(voiceSearchService.cancelListening());
    }
    super.dispose();
  }

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
          child: _TextVoiceSearchField(
            controller: widget.controller,
            label: widget.label,
            hintText: widget.hintText,
            fieldKey: widget.fieldKey,
            clearButtonKey: widget.clearButtonKey,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            isSearching: widget.isSearching,
            prefixIcon: widget.prefixIcon,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onClearPressed: _handleClearPressed,
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
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _attachVoiceSearchController() {
    widget.voiceSearchController?._attach(
      stopVoiceSearchIfNeeded: stopVoiceSearchIfNeeded,
      cancelVoiceSearch: cancelVoiceSearch,
    );
  }
}

class _TextVoiceSearchField extends StatelessWidget {
  const _TextVoiceSearchField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.fieldKey,
    required this.clearButtonKey,
    required this.readOnly,
    required this.autofocus,
    required this.enabled,
    required this.isSearching,
    required this.prefixIcon,
    required this.onTap,
    required this.onChanged,
    required this.onClearPressed,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final Key fieldKey;
  final Key? clearButtonKey;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final bool isSearching;
  final Widget? prefixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: TextInputType.text,
          readOnly: readOnly,
          autofocus: autofocus,
          enabled: enabled,
          minLines: 1,
          maxLines: _textVoiceSearchMaxLines,
          inputFormatters: _textVoiceSearchInputFormatters,
          onTap: onTap,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: hintText == null ? label : null,
            hintText: hintText,
            floatingLabelBehavior: hintText == null
                ? FloatingLabelBehavior.auto
                : FloatingLabelBehavior.never,
            prefixIcon: prefixIcon ?? const Icon(Icons.search),
            suffixIcon: _TextVoiceSearchSuffixActions(
              isSearching: isSearching,
              hasText: hasText,
              enabled: enabled,
              clearButtonKey: clearButtonKey,
              onClearPressed: onClearPressed,
            ),
          ),
        );
      },
    );
  }
}

class _TextVoiceSearchSuffixActions extends StatelessWidget {
  const _TextVoiceSearchSuffixActions({
    required this.isSearching,
    required this.hasText,
    required this.enabled,
    required this.clearButtonKey,
    required this.onClearPressed,
  });

  final bool isSearching;
  final bool hasText;
  final bool enabled;
  final Key? clearButtonKey;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    if (!isSearching && !hasText) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (hasText)
          IconButton(
            key: clearButtonKey,
            onPressed: enabled ? onClearPressed : null,
            tooltip: AppLocalizations.of(context)!.inventorySearchClearAction,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
      ],
    );
  }
}
