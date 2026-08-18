import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_actions/product_search_hub_search_actions.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_bar/product_search_hub_search_bar.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_results/product_search_hub_search_results.dart';

const _productSearchHubSearchActionsAppearDuration = Duration(
  milliseconds: 90,
);

/// Visual shell for focused product search page.
class ProductSearchHubSearchPageContent extends StatelessWidget {
  /// Creates focused search page content.
  const ProductSearchHubSearchPageContent({
    required this.title,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.startVoiceSearchOnMount,
    required this.showFocusedSearchField,
    required this.isClosing,
    required this.hasSearchQuery,
    required this.searchResults,
    required this.hasSearchFailed,
    required this.onBackPressed,
    required this.onSearchChanged,
    required this.onClear,
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    required this.onBlankTap,
    required this.onRetry,
    required this.onResultSelected,
    this.autofocusSearchField = true,
    super.key,
  });

  /// Page title.
  final String title;

  /// Search text controller.
  final TextEditingController searchController;

  /// Search focus node.
  final FocusNode searchFocusNode;

  /// Whether search is running.
  final bool isSearching;

  /// Voice search service.
  final VoiceSearchService voiceSearchService;

  /// Voice search controller.
  final TextVoiceSearchController voiceSearchController;

  /// Whether voice should auto-start after mount.
  final bool startVoiceSearchOnMount;

  /// Whether focused field is visible.
  final bool showFocusedSearchField;

  /// Whether page is closing.
  final bool isClosing;

  /// Whether enough query text exists.
  final bool hasSearchQuery;

  /// Search results.
  final List<OffProductSearchResult> searchResults;

  /// Whether search field should autofocus.
  final bool autofocusSearchField;

  /// Whether search failed.
  final bool hasSearchFailed;

  /// Back callback.
  final VoidCallback onBackPressed;

  /// Search text callback.
  final ValueChanged<String> onSearchChanged;

  /// Clear callback.
  final VoidCallback onClear;

  /// Barcode callback.
  final VoidCallback onBarcodePressed;

  /// AI callback.
  final VoidCallback onAiPressed;

  /// Create own callback.
  final VoidCallback onCreateOwnPressed;

  /// Blank area tap callback.
  final VoidCallback onBlankTap;

  /// Retry callback.
  final VoidCallback onRetry;

  /// Result selected callback.
  final ValueChanged<OffProductSearchResult> onResultSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: onBackPressed),
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              _ProductSearchHubSearchFieldStack(
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                isSearching: isSearching,
                voiceSearchService: voiceSearchService,
                voiceSearchController: voiceSearchController,
                startVoiceSearchOnMount: startVoiceSearchOnMount,
                showFocusedSearchField: showFocusedSearchField,
                autofocusSearchField: autofocusSearchField,
                isClosing: isClosing,
                onSearchChanged: onSearchChanged,
                onClear: onClear,
              ),
              _ProductSearchHubSearchActionSection(
                isVisible: showFocusedSearchField && !isClosing,
                onBarcodePressed: onBarcodePressed,
                onAiPressed: onAiPressed,
                onCreateOwnPressed: onCreateOwnPressed,
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!hasSearchQuery) {
      return _ProductSearchHubSearchBlank(onTap: onBlankTap);
    }
    return ProductSearchHubSearchResults(
      results: searchResults,
      isSearching: isSearching,
      hasFailed: hasSearchFailed,
      onCreateOwnPressed: onCreateOwnPressed,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      onRetry: onRetry,
      onResultSelected: onResultSelected,
    );
  }
}

class _ProductSearchHubSearchFieldStack extends StatelessWidget {
  const _ProductSearchHubSearchFieldStack({
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.startVoiceSearchOnMount,
    required this.showFocusedSearchField,
    required this.autofocusSearchField,
    required this.isClosing,
    required this.onSearchChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearching;
  final VoiceSearchService voiceSearchService;
  final TextVoiceSearchController voiceSearchController;
  final bool startVoiceSearchOnMount;
  final bool showFocusedSearchField;
  final bool autofocusSearchField;
  final bool isClosing;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: productSearchHubSearchBarHeroTag,
          child: _ProductSearchHubSearchHeroField(
            isVisible: !showFocusedSearchField || isClosing,
          ),
        ),
        if (showFocusedSearchField && !isClosing)
          ProductSearchHubSearchBar(
            controller: searchController,
            focusNode: searchFocusNode,
            isSearching: isSearching,
            voiceSearchService: voiceSearchService,
            voiceSearchController: voiceSearchController,
            startVoiceSearchOnMount: startVoiceSearchOnMount,
            autofocus: autofocusSearchField,
            onChanged: onSearchChanged,
            onClear: onClear,
          ),
      ],
    );
  }
}

class _ProductSearchHubSearchActionSection extends StatelessWidget {
  const _ProductSearchHubSearchActionSection({
    required this.isVisible,
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
  });

  final bool isVisible;
  final VoidCallback onBarcodePressed;
  final VoidCallback onAiPressed;
  final VoidCallback onCreateOwnPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _productSearchHubSearchActionsAppearDuration,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isVisible
          ? Column(
              key: const Key('product_search_hub_search_actions_section'),
              children: [
                const SizedBox(height: AppSpacing.md),
                ProductSearchHubSearchActions(
                  onBarcodePressed: onBarcodePressed,
                  onAiPressed: onAiPressed,
                  onCreateOwnPressed: onCreateOwnPressed,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ProductSearchHubSearchHeroField extends StatelessWidget {
  const _ProductSearchHubSearchHeroField({required this.isVisible});

  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: Opacity(
          opacity: isVisible ? 1 : 0,
          child: const ProductSearchHubSearchBar(
            isSearching: false,
            readOnly: true,
            fieldKey: Key('product_search_hub_search_hero_field'),
          ),
        ),
      ),
    );
  }
}

class _ProductSearchHubSearchBlank extends StatelessWidget {
  const _ProductSearchHubSearchBlank({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox.expand(),
    );
  }
}
