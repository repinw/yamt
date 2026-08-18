import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows dialog asking user for their name before joining a household.
Future<String?> showHouseholdJoinNameDialog({
  required BuildContext context,
  required AppLocalizations l10n,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => HouseholdJoinNameDialog(l10n: l10n),
  );
}

/// Defines household join name dialog.
class HouseholdJoinNameDialog extends StatefulWidget {
  /// Creates the dialog.
  const HouseholdJoinNameDialog({required this.l10n, super.key});

  /// The l10n instance.
  final AppLocalizations l10n;

  @override
  State<HouseholdJoinNameDialog> createState() =>
      _HouseholdJoinNameDialogState();
}

class _HouseholdJoinNameDialogState extends State<HouseholdJoinNameDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.householdJoinNameDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.l10n.householdJoinNameDialogMessage),
            const SizedBox(height: AppSpacing.md),
            _HouseholdJoinNameTextField(
              controller: _nameController,
              label: widget.l10n.householdJoinNameDialogFieldLabel,
              requiredError: widget.l10n.householdJoinNameDialogRequiredError,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.l10n.householdJoinNameDialogAction),
        ),
      ],
    );
  }
}

class _HouseholdJoinNameTextField extends StatelessWidget {
  const _HouseholdJoinNameTextField({
    required this.controller,
    required this.label,
    required this.requiredError,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String label;
  final String requiredError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      onFieldSubmitted: (_) => onSubmit(),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return requiredError;
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}
