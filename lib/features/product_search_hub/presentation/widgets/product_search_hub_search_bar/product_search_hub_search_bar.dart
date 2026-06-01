import 'package:flutter/material.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared hero tag for the hub search field transition.
const productSearchHubSearchBarHeroTag = 'product_search_hub_search_bar_hero';

/// Local product search input for the hub shell.
class ProductSearchHubSearchBar extends StatefulWidget {
  /// Creates product search hub search bar.
  const ProductSearchHubSearchBar({
    required this.isSearching,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.onTap,
    this.voiceSearchService,
    this.voiceSearchController,
    this.onVoiceSearchPressed,
    this.startVoiceSearchOnMount = false,
    this.readOnly = false,
    this.autofocus = false,
    this.fieldKey = const Key('product_search_hub_search_field'),
    super.key,
  });

  /// Search text controller.
  final TextEditingController? controller;

  /// Search field focus node.
  final FocusNode? focusNode;

  /// Whether search request is running.
  final bool isSearching;

  /// Called when search text changes.
  final ValueChanged<String>? onChanged;

  /// Clear search action.
  final VoidCallback? onClear;

  /// Tap action.
  final VoidCallback? onTap;

  /// Optional voice search service.
  final VoiceSearchService? voiceSearchService;

  /// Optional voice search controller.
  final TextVoiceSearchController? voiceSearchController;

  /// Optional external voice action.
  final VoidCallback? onVoiceSearchPressed;

  /// Whether voice search should start after mount.
  final bool startVoiceSearchOnMount;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the field should request focus when shown.
  final bool autofocus;

  /// Key used by the inner text field.
  final Key fieldKey;

  @override
  State<ProductSearchHubSearchBar> createState() =>
      _ProductSearchHubSearchBarState();
}

class _ProductSearchHubSearchBarState extends State<ProductSearchHubSearchBar> {
  late final TextEditingController _fallbackController;

  TextEditingController get _controller {
    return widget.controller ?? _fallbackController;
  }

  @override
  void initState() {
    super.initState();
    _fallbackController = TextEditingController();
  }

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextVoiceSearchBar(
      controller: _controller,
      label: l10n.productSearchHubSearchHint,
      fieldKey: widget.fieldKey,
      voiceButtonKey: const Key('product_search_hub_voice_search_button'),
      clearButtonKey: const Key('product_search_hub_search_clear_button'),
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      isSearching: widget.isSearching,
      startVoiceSearchOnMount: widget.startVoiceSearchOnMount,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onClearPressed: widget.onClear,
      voiceSearchService: widget.voiceSearchService,
      voiceSearchController: widget.voiceSearchController,
      onVoiceSearchPressed: widget.onVoiceSearchPressed,
      hintText: l10n.productSearchHubSearchHint,
      clearTooltip: l10n.productSearchHubClearSearchAction,
      useCompactSurface: true,
    );
  }
}
