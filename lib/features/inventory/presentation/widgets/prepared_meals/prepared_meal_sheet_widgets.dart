import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shared prepared meal bottom sheet layout.
class PreparedMealSheetContainer extends StatelessWidget {
  /// The prepared meal sheet container.
  const PreparedMealSheetContainer({
    required this.formKey,
    required this.children,
    super.key,
  });

  /// The form key used by the sheet.
  final GlobalKey<FormState> formKey;

  /// The scrollable sheet children.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxxl,
        ),
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppInventoryEditorial.cardRadius,
            ),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Defines shared prepared meal name field.
class PreparedMealNameField extends StatelessWidget {
  /// The prepared meal name field.
  const PreparedMealNameField({
    required this.controller,
    required this.textInputAction,
    super.key,
    this.onChanged,
  });

  /// The field controller.
  final TextEditingController controller;

  /// The keyboard action.
  final TextInputAction textInputAction;

  /// Called when the name changes.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: l10n.preparedMealNameLabel,
        suffixIcon: IconButton(
          tooltip: l10n.preparedMealClearNameAction,
          onPressed: () {
            controller.clear();
            onChanged?.call(controller.text);
          },
          icon: const Icon(Icons.cleaning_services_outlined),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.preparedMealInvalidName;
        }
        return null;
      },
    );
  }
}

/// Defines shared prepared meal sheet actions.
class PreparedMealSheetActions extends StatelessWidget {
  /// The prepared meal sheet actions.
  const PreparedMealSheetActions({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    super.key,
  });

  /// The primary action label.
  final String primaryLabel;

  /// Called when the primary action is pressed.
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: onPrimaryPressed,
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
