import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory list top controls sliver.
class InventoryListTopControlsSliver extends StatelessWidget {
  /// The inventory list top controls sliver.
  const InventoryListTopControlsSliver({
    required this.modeToggle,
    required this.showSearch,
    required this.searchController,
    required this.enabled,
    required this.onSearchChanged,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.l10n,
    super.key,
  });

  /// The mode toggle.
  final Widget modeToggle;

  /// The show search.
  final bool showSearch;

  /// The search controller.
  final TextEditingController searchController;

  /// The enabled.
  final bool enabled;

  /// The on search changed.
  final ValueChanged<String> onSearchChanged;

  /// The voice search service.
  final VoiceSearchService voiceSearchService;

  /// The voice search controller.
  final TextVoiceSearchController voiceSearchController;

  /// The l10n.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            modeToggle,
            if (showSearch) ...[
              const SizedBox(height: AppSpacing.lg),
              TextVoiceSearchBar(
                controller: searchController,
                label: l10n.inventorySearchLabel,
                fieldKey: const Key('inventory_list_search_field'),
                voiceButtonKey: const Key('inventory_list_voice_search_button'),
                clearButtonKey: const Key('inventory_list_search_clear_button'),
                enabled: enabled,
                onChanged: onSearchChanged,
                voiceSearchService: voiceSearchService,
                voiceSearchController: voiceSearchController,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
