import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Shared amount input card for inventory eat flows.
class InventoryEatFlowAmountCard extends StatelessWidget {
  /// Creates amount input card.
  const InventoryEatFlowAmountCard({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.allowFractionalInput,
    required this.clearTooltip,
    required this.fieldKey,
    required this.clearButtonKey,
    required this.trailing,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
    this.clearIcon = Icons.cleaning_services_outlined,
    super.key,
  });

  static const _amountFieldWidth = 100.0;

  /// Text controller.
  final TextEditingController controller;

  /// Focus node.
  final FocusNode focusNode;

  /// Error text.
  final String? errorText;

  /// Whether field allows decimal input.
  final bool allowFractionalInput;

  /// Clear tooltip.
  final String clearTooltip;

  /// Field key.
  final Key fieldKey;

  /// Clear button key.
  final Key clearButtonKey;

  /// Clear button icon.
  final IconData clearIcon;

  /// Trailing content beside amount.
  final Widget trailing;

  /// Change callback.
  final ValueChanged<String> onChanged;

  /// Clear/focus callback.
  final VoidCallback onClearAndFocus;

  /// Submit callback.
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colors.primary.withValues(
                alpha: focusNode.hasFocus ? 0.72 : 0.28,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                SizedBox(
                  width: _amountFieldWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.lg,
                    ),
                    child: TextField(
                      key: fieldKey,
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: allowFractionalInput,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        isCollapsed: true,
                      ),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 64,
                  color: AppInventoryEditorialSurfaces.ghostBorder(colors),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.md,
                    ),
                    child: trailing,
                  ),
                ),
                IconButton(
                  key: clearButtonKey,
                  tooltip: clearTooltip,
                  onPressed: onClearAndFocus,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(clearIcon),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
