import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_voice_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _textVoiceSearchMaxLines = 3;
final _textVoiceSearchInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
];

/// Text field half of `TextVoiceSearchBar`, with clear and voice actions.
class TextVoiceSearchField extends StatelessWidget {
  /// Creates the search text field with its trailing actions.
  const new({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.fieldKey,
    required this.clearButtonKey,
    required this.focusNode,
    required this.readOnly,
    required this.autofocus,
    required this.enabled,
    required this.isSearching,
    required this.prefixIcon,
    required this.useCompactSurface,
    required this.clearTooltip,
    required this.voiceButtonKey,
    required this.isVoiceListening,
    required this.voiceTooltip,
    required this.onVoiceButtonPressed,
    required this.onTap,
    required this.onChanged,
    required this.onClearPressed,
    super.key,
  });

  /// Controller that holds current search text.
  final TextEditingController controller;

  /// Localized field label.
  final String label;

  /// Optional hint text shown inside the field instead of a floating label.
  final String? hintText;

  /// Widget key for the text field.
  final Key fieldKey;

  /// Optional key for the clear button.
  final Key? clearButtonKey;

  /// Optional focus node for the text field.
  final FocusNode? focusNode;

  /// Whether text field should be read-only.
  final bool readOnly;

  /// Whether text field should autofocus.
  final bool autofocus;

  /// Whether all controls are enabled.
  final bool enabled;

  /// Whether a search request is currently in progress.
  final bool isSearching;

  /// Optional custom prefix icon for field.
  final Widget? prefixIcon;

  /// Whether to render the compact filled search style.
  final bool useCompactSurface;

  /// Optional clear button tooltip.
  final String? clearTooltip;

  /// Optional key for the voice button.
  final Key? voiceButtonKey;

  /// Whether the voice button should render its listening state.
  final bool isVoiceListening;

  /// Tooltip shown on the voice button.
  final String voiceTooltip;

  /// Handler invoked when the voice button is pressed.
  final VoidCallback onVoiceButtonPressed;

  /// Optional tap callback for the text field.
  final VoidCallback? onTap;

  /// Optional change callback for the text field.
  final ValueChanged<String>? onChanged;

  /// Handler invoked when the clear button is pressed.
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final voiceButton = TextVoiceSearchVoiceButton(
      key: voiceButtonKey,
      enabled: enabled,
      isListening: isVoiceListening,
      onPressed: onVoiceButtonPressed,
      tooltip: voiceTooltip,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        final colors = Theme.of(context).colorScheme;
        final borderRadius = BorderRadius.circular(AppRadius.lg);
        final border = useCompactSurface
            ? OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide.none,
              )
            : null;

        final field = TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.text,
          readOnly: readOnly,
          autofocus: autofocus,
          enabled: enabled,
          minLines: 1,
          maxLines: _textVoiceSearchMaxLines,
          inputFormatters: _textVoiceSearchInputFormatters,
          onTap: onTap,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          textAlignVertical: useCompactSurface ? TextAlignVertical.top : null,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontSize: useCompactSurface
                ? AppFontSizes.compactSearchInput
                : null,
            fontWeight: useCompactSurface ? FontWeight.w500 : null,
          ),
          decoration: InputDecoration(
            labelText: hintText == null ? label : null,
            hintText: hintText,
            hintStyle: useCompactSurface
                ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(
                      alpha: AppOpacities.compactSearchHint,
                    ),
                    fontSize: AppFontSizes.compactSearchInput,
                    fontWeight: FontWeight.w500,
                  )
                : null,
            filled: useCompactSurface ? true : null,
            fillColor: useCompactSurface
                ? colors.surfaceContainerHigh.withValues(
                    alpha: AppOpacities.compactSearchSurface,
                  )
                : null,
            isDense: useCompactSurface ? true : null,
            contentPadding: useCompactSurface
                ? const EdgeInsets.symmetric(vertical: AppSpacing.lg)
                : null,
            border: border,
            enabledBorder: border,
            focusedBorder: useCompactSurface
                ? border?.copyWith(
                    borderSide: BorderSide(
                      color: colors.primary.withValues(
                        alpha: AppOpacities.compactSearchFocusBorder,
                      ),
                    ),
                  )
                : null,
            disabledBorder: border,
            floatingLabelBehavior: hintText == null
                ? FloatingLabelBehavior.auto
                : FloatingLabelBehavior.never,
            prefixIcon: prefixIcon ?? const _TextVoiceSearchPrefixIcon(),
            prefixIconConstraints: useCompactSurface
                ? const BoxConstraints(
                    minWidth: AppSizes.compactSearchPrefixWidth,
                    minHeight: AppSizes.compactSearchControlHeight,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: AppSizes.compactSearchInlineAction,
              minHeight: AppSizes.compactSearchInlineAction,
            ),
            suffixIcon: _TextVoiceSearchSuffixActions(
              isSearching: isSearching,
              hasText: hasText,
              enabled: enabled,
              clearButtonKey: clearButtonKey,
              clearTooltip: clearTooltip,
              voiceButton: voiceButton,
              onClearPressed: onClearPressed,
            ),
          ),
        );

        if (!useCompactSurface) {
          return field;
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.compactSearchControlHeight,
          ),
          child: field,
        );
      },
    );
  }
}

class _TextVoiceSearchPrefixIcon extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Icon(
      Icons.search_rounded,
      size: AppSizes.compactSearchIcon,
      color: colors.onSurfaceVariant.withValues(
        alpha: AppOpacities.compactSearchPrefixIcon,
      ),
    );
  }
}

class _TextVoiceSearchSuffixActions extends StatelessWidget {
  const new({
    required this.isSearching,
    required this.hasText,
    required this.enabled,
    required this.clearButtonKey,
    required this.clearTooltip,
    required this.voiceButton,
    required this.onClearPressed,
  });

  final bool isSearching;
  final bool hasText;
  final bool enabled;
  final Key? clearButtonKey;
  final String? clearTooltip;
  final Widget voiceButton;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    if (!isSearching && !hasText) {
      return voiceButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SizedBox.square(
              dimension: AppSizes.smallProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
              ),
            ),
          ),
        if (hasText)
          IconButton(
            key: clearButtonKey,
            onPressed: enabled ? onClearPressed : null,
            tooltip:
                clearTooltip ??
                AppLocalizations.of(context)!.inventorySearchClearAction,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        voiceButton,
      ],
    );
  }
}
