import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory list top controls sliver.
class InventoryListTopControlsSliver extends StatelessWidget {
  /// The inventory list top controls sliver.
  const new({
    required this.showSearch,
    required this.searchController,
    required this.enabled,
    required this.onSearchChanged,
    required this.onShowFilters,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.l10n,
    super.key,
  });

  /// The show search.
  final bool showSearch;

  /// The search controller.
  final TextEditingController searchController;

  /// The enabled.
  final bool enabled;

  /// The on search changed.
  final ValueChanged<String> onSearchChanged;

  /// Opens the unified filter menu.
  final VoidCallback onShowFilters;

  /// The voice search service.
  final VoiceSearchService voiceSearchService;

  /// The voice search controller.
  final TextVoiceSearchController voiceSearchController;

  /// The l10n.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (!showSearch) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: responsivePagePadding(
        context,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      sliver: SliverToBoxAdapter(
        child: TextVoiceSearchBar(
          controller: searchController,
          label: l10n.inventorySearchLabel,
          fieldKey: const Key('inventory_list_search_field'),
          voiceButtonKey: const Key('inventory_list_voice_search_button'),
          clearButtonKey: const Key('inventory_list_search_clear_button'),
          enabled: enabled,
          onChanged: onSearchChanged,
          voiceSearchService: voiceSearchService,
          voiceSearchController: voiceSearchController,
          hintText: l10n.inventorySearchLabel,
          useCompactSurface: true,
          trailingActions: [
            _InventorySearchSettingsButton(
              enabled: enabled,
              label: l10n.inventoryFilterSectionTitle,
              onPressed: onShowFilters,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tonal "Filter" button next to the search field: its word says that it
/// opens the view, sort and filter settings.
class _InventorySearchSettingsButton extends StatelessWidget {
  const new({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.compactSearchControlHeight,
      child: FilledButton.tonalIcon(
        key: const Key('inventory_list_search_settings_button'),
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        icon: const Icon(
          Icons.tune_rounded,
          size: AppSizes.compactSearchSettingsIcon,
        ),
        label: Text(label),
      ),
    );
  }
}
