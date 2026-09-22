import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Search input bar with voice recognition and generate button for the
/// AI search page.
class ProductAiPromptBar extends StatelessWidget {
  /// Creates a prompt bar.
  const new({
    required this.promptController,
    required this.voiceSearchController,
    required this.voiceSearchService,
    required this.isLoading,
    required this.onGenerate,
    this.autofocus = false,
    super.key,
  });

  /// Text controller for the food prompt.
  final TextEditingController promptController;

  /// Voice search state controller.
  final TextVoiceSearchController voiceSearchController;

  /// Platform speech-to-text service.
  final VoiceSearchService voiceSearchService;

  /// Whether draft generation is in progress.
  final bool isLoading;

  /// Whether to autofocus the prompt text field.
  final bool autofocus;

  /// Called when the generate button is tapped.
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextVoiceSearchBar(
          controller: promptController,
          label: l10n.inventoryManualAddAiSearchPromptLabel,
          hintText: l10n.inventoryManualAddAiSearchPromptHint,
          fieldKey: const Key('manual_product_ai_prompt_field'),
          voiceButtonKey: const Key('manual_product_ai_voice_search_button'),
          clearButtonKey: const Key('manual_product_ai_prompt_clear_button'),
          autofocus: autofocus,
          enabled: !isLoading,
          voiceSearchService: voiceSearchService,
          voiceSearchController: voiceSearchController,
          prefixIcon: const Icon(Icons.auto_awesome_outlined),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('manual_product_ai_generate_button'),
            onPressed: isLoading ? null : onGenerate,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.inventoryManualAddAiSearchGenerateAction),
          ),
        ),
      ],
    );
  }
}
