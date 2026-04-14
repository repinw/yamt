import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryListTopControlsSliver extends StatelessWidget {
  const InventoryListTopControlsSliver({
    super.key,
    required this.modeToggle,
    required this.showSearch,
    required this.searchController,
    required this.enabled,
    required this.onSearchChanged,
    required this.voiceSearchService,
    required this.voiceSearchController,
    required this.l10n,
  });

  final Widget modeToggle;
  final bool showSearch;
  final TextEditingController searchController;
  final bool enabled;
  final ValueChanged<String> onSearchChanged;
  final VoiceSearchService voiceSearchService;
  final TextVoiceSearchController voiceSearchController;
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
