import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_text_styles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Caption of the note card.
class CookingFlowOnTheFlyHeader extends StatelessWidget {
  /// Creates the caption.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.cookflowOnTheFlyTitle.toUpperCase(),
      style: context.cookingFlowKickerStyle,
    );
  }
}

/// Text field, voice button and the add button of the note card.
class CookingFlowOnTheFlyInputRow extends StatelessWidget {
  /// Creates the input row.
  const new({
    required this.controller,
    required this.isListeningToSpeech,
    required this.onVoicePressed,
    required this.onAddPressed,
    super.key,
  });

  /// Text of the note.
  final TextEditingController controller;

  /// Whether the microphone is listening.
  final bool isListeningToSpeech;

  /// Starts or stops the voice input.
  final VoidCallback onVoicePressed;

  /// Adds the note.
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            key: const Key('cookflow_on_the_fly_field'),
            controller: controller,
            cursorColor: colors.ink,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink),
            decoration: InputDecoration(
              hintText: l10n.cookflowOnTheFlyHint,
              hintStyle: textTheme.bodyMedium?.copyWith(color: colors.muted),
              isDense: true,
              filled: true,
              fillColor: colors.tile,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CookingFlowVoiceInputButton(
          isListeningToSpeech: isListeningToSpeech,
          onPressed: onVoicePressed,
        ),
        const SizedBox(width: AppSpacing.xs),
        CookingFlowSecondaryActionButton(
          key: const Key('cookflow_on_the_fly_add_button'),
          label: l10n.cookflowOnTheFlyAddButton,
          onPressed: onAddPressed,
        ),
      ],
    );
  }
}

/// Microphone toggle. While listening it is filled with ink.
class CookingFlowVoiceInputButton extends StatelessWidget {
  /// Creates the toggle.
  const new({
    required this.isListeningToSpeech,
    required this.onPressed,
    super.key,
  });

  /// Whether the microphone is listening.
  final bool isListeningToSpeech;

  /// Starts or stops the voice input.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const Key('cookflow_on_the_fly_voice_button'),
      onPressed: onPressed,
      tooltip: isListeningToSpeech
          ? l10n.cookflowVoiceInputStopTooltip
          : l10n.cookflowVoiceInputStartTooltip,
      style: IconButton.styleFrom(
        backgroundColor: isListeningToSpeech ? colors.ink : colors.tile,
        foregroundColor: isListeningToSpeech ? colors.paper : colors.ink,
        minimumSize: const Size.square(AppGraphit.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: Icon(
        isListeningToSpeech ? Icons.mic : Icons.mic_none,
        size: AppGraphit.toolIcon,
      ),
    );
  }
}

/// The last notes, newest at the bottom, each with a remove button.
class CookingFlowOnTheFlyRecentAdjustments extends StatelessWidget {
  /// Creates the list.
  const new({
    required this.adjustments,
    required this.startIndex,
    required this.onRemovePressed,
    super.key,
  });

  /// Notes to show.
  final List<String> adjustments;

  /// Index of the first shown note in the full list.
  final int startIndex;

  /// Removes the note at the index in the full list.
  final void Function(int index) onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 56),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            for (var index = 0; index < adjustments.length; index++) ...[
              _CookingFlowOnTheFlyAdjustmentChip(
                adjustment: adjustments[index],
                onRemovePressed: () => onRemovePressed(startIndex + index),
              ),
              if (index != adjustments.length - 1)
                const SizedBox(height: AppSpacing.xxs),
            ],
          ],
        ),
      ),
    );
  }
}

class _CookingFlowOnTheFlyAdjustmentChip extends StatelessWidget {
  const new({required this.adjustment, required this.onRemovePressed});

  final String adjustment;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              adjustment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.ink),
            ),
          ),
          SizedBox.square(
            dimension: AppGraphit.badge,
            child: IconButton(
              key: const Key('cookflow_on_the_fly_remove_button'),
              onPressed: onRemovePressed,
              tooltip: l10n.cookflowOnTheFlyRemoveTooltip,
              iconSize: AppGraphit.chipIcon,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              color: colors.muted,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
