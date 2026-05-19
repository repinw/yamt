import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory list top controls sliver.
class InventoryListTopControlsSliver extends StatelessWidget {
  /// The inventory list top controls sliver.
  const InventoryListTopControlsSliver({
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
              tooltip: l10n.inventoryFilterAction,
              onPressed: onShowFilters,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySearchSettingsButton extends StatelessWidget {
  const _InventorySearchSettingsButton({
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: AppSizes.compactSearchControlHeight,
      child: IconButton(
        key: const Key('inventory_list_search_settings_button'),
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceContainerHigh.withValues(alpha: 0.72),
          foregroundColor: colors.onSurfaceVariant.withValues(alpha: 0.86),
          disabledBackgroundColor: colors.surfaceContainerHigh.withValues(
            alpha: 0.38,
          ),
          disabledForegroundColor: colors.onSurfaceVariant.withValues(
            alpha: 0.38,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        icon: const Icon(Icons.tune_rounded, size: 21),
      ),
    );
  }
}
