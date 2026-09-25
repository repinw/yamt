import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_bar/product_search_hub_search_bar.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_page_content/'
    'product_search_hub_search_page_sections.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_results/product_search_hub_search_results.dart';

/// Visual shell for focused product search page.
class ProductSearchHubSearchPageContent extends StatelessWidget {
  /// Creates focused search page content.
  const new({
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
    required this.onRecentItemPressed,
    required this.onRecentItemCopied,
    this.onResultCopied,
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

  /// Result copied callback.
  final ValueChanged<OffProductSearchResult>? onResultCopied;

  /// Recent product selected callback.
  final ValueChanged<InventoryItem> onRecentItemPressed;

  /// Recent product copied callback.
  final ValueChanged<InventoryItem> onRecentItemCopied;

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
              ProductSearchHubSearchActionSection(
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
      if (!showFocusedSearchField || isClosing) {
        return ProductSearchHubSearchBlank(onTap: onBlankTap);
      }
      return ProductSearchHubSearchRecentSection(
        onProductPressed: onRecentItemPressed,
        onProductCopied: onRecentItemCopied,
      );
    }
    return ProductSearchHubSearchResults(
      results: searchResults,
      isSearching: isSearching,
      hasFailed: hasSearchFailed,
      onCreateOwnPressed: onCreateOwnPressed,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      onRetry: onRetry,
      onResultSelected: onResultSelected,
      onResultCopied: onResultCopied,
    );
  }
}

class _ProductSearchHubSearchFieldStack extends StatelessWidget {
  const new({
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
          child: ProductSearchHubSearchHeroField(
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
