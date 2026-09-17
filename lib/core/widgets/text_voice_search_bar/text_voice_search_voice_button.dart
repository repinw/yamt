import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Compact microphone button used by `TextVoiceSearchField`.
class TextVoiceSearchVoiceButton extends StatelessWidget {
  /// Creates the voice search trigger button.
  const new({
    required this.enabled,
    required this.isListening,
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  /// Whether the button responds to taps.
  final bool enabled;

  /// Whether a voice search session is currently active.
  final bool isListening;

  /// Callback invoked when the button is pressed.
  final VoidCallback onPressed;

  /// Tooltip shown for the button.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = isListening
        ? colors.primary
        : colors.onSurfaceVariant.withValues(
            alpha: AppOpacities.compactSearchTrailingIcon,
          );

    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(AppSpacing.xs),
      constraints: const BoxConstraints.tightFor(
        width: AppSizes.compactSearchInlineAction,
        height: AppSizes.compactSearchInlineAction,
      ),
      icon: Icon(
        isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
        size: AppSizes.compactSearchIcon,
        color: enabled
            ? foregroundColor
            : colors.onSurfaceVariant.withValues(
                alpha: AppOpacities.compactSearchDisabled,
              ),
      ),
    );
  }
}
