import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product search input of the product search hub.
class ProductSearchHubSearchBar extends StatelessWidget {
  /// Creates product search hub search bar.
  const new({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  /// Search text controller.
  final TextEditingController controller;

  /// Search field focus node.
  final FocusNode focusNode;

  /// Whether search request is running.
  final bool isSearching;

  /// Voice search service.
  final VoiceSearchService voiceSearchService;

  /// Voice search controller.
  final TextVoiceSearchController voiceSearchController;

  /// Called when search text changes.
  final ValueChanged<String> onChanged;

  /// Clear search action.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextVoiceSearchBar(
      controller: controller,
      label: l10n.productSearchHubSearchHint,
      fieldKey: const Key('product_search_hub_search_field'),
      voiceButtonKey: const Key('product_search_hub_voice_search_button'),
      clearButtonKey: const Key('product_search_hub_search_clear_button'),
      focusNode: focusNode,
      isSearching: isSearching,
      onChanged: onChanged,
      onClearPressed: onClear,
      voiceSearchService: voiceSearchService,
      voiceSearchController: voiceSearchController,
      hintText: l10n.productSearchHubSearchHint,
      clearTooltip: l10n.productSearchHubClearSearchAction,
      useCompactSurface: true,
    );
  }
}
