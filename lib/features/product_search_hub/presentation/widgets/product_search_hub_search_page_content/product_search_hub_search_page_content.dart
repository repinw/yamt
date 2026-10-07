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

/// Visual shell for the product search hub page.
class ProductSearchHubSearchPageContent extends StatelessWidget {
  /// Creates search page content.
  const new({
    required this.title,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.hasSearchQuery,
    required this.searchResults,
    required this.hasSearchFailed,
    required this.onBackPressed,
    required this.onSearchChanged,
    required this.onClear,
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    required this.onRetry,
    required this.onResultSelected,
    required this.onRecentItemPressed,
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

  /// Whether enough query text exists.
  final bool hasSearchQuery;

  /// Search results.
  final List<OffProductSearchResult> searchResults;

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

  /// Retry callback.
  final VoidCallback onRetry;

  /// Result selected callback.
  final ValueChanged<OffProductSearchResult> onResultSelected;

  /// Recent product selected callback.
  final ValueChanged<InventoryItem> onRecentItemPressed;

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
              ProductSearchHubSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                isSearching: isSearching,
                voiceSearchService: voiceSearchService,
                voiceSearchController: voiceSearchController,
                onChanged: onSearchChanged,
                onClear: onClear,
              ),
              ProductSearchHubSearchActionSection(
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
      return ProductSearchHubSearchRecentSection(
        onProductPressed: onRecentItemPressed,
      );
    }
    return ProductSearchHubSearchResults(
      results: searchResults,
      isSearching: isSearching,
      hasFailed: hasSearchFailed,
      onCreateOwnPressed: onCreateOwnPressed,
      onRetry: onRetry,
      onResultSelected: onResultSelected,
    );
  }
}
