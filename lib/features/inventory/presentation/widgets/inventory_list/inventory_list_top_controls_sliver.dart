import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Search field of the Vorrat list with the Sortieren button.
class InventoryListTopControlsSliver extends StatelessWidget {
  /// The inventory list top controls sliver.
  const new({
    required this.showSearch,
    required this.searchController,
    required this.enabled,
    required this.onSearchChanged,
    required this.onShowSort,
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

  /// Opens the Sortieren sheet.
  final VoidCallback onShowSort;

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
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
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
            _ToolButton(
              key: const Key('inventory_list_sort_button'),
              enabled: enabled,
              icon: Icons.filter_alt_rounded,
              label: l10n.inventorySortAction,
              onPressed: onShowSort,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tonal button with an icon and a word next to the search field.
class _ToolButton extends StatelessWidget {
  const new({
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.compactSearchControlHeight,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        icon: Icon(icon, size: AppSizes.compactSearchSettingsIcon),
        label: Text(label),
      ),
    );
  }
}
