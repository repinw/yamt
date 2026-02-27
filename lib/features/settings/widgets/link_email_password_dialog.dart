import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shared/widgets/email_password_credentials_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

class LinkEmailPasswordDialog extends StatefulWidget {
  const LinkEmailPasswordDialog({
    super.key,
    required this.l10n,
    required this.onSubmitCredentials,
    required this.errorMessageFor,
  });

  final AppLocalizations l10n;
  final Future<void> Function({required String email, required String password})
  onSubmitCredentials;
  final String Function(Object error) errorMessageFor;

  @override
  State<LinkEmailPasswordDialog> createState() =>
      _LinkEmailPasswordDialogState();
}

class _LinkEmailPasswordDialogState extends State<LinkEmailPasswordDialog> {
  final _formKey = GlobalKey<EmailPasswordCredentialsFormState>();
  var _isSubmitting = false;
  String? _submitError;

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _submitError = null;
      _isSubmitting = true;
    });

    try {
      final didSubmit =
          await (_formKey.currentState?.submit() ?? Future.value(false));
      if (!mounted) {
        return;
      }
      if (!didSubmit) {
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = widget.errorMessageFor(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.l10n.accountPageLinkEmailPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.l10n.accountPageLinkEmailPasswordDescription),
          const SizedBox(height: AppSpacing.md),
          EmailPasswordCredentialsForm(
            key: _formKey,
            submitLabel: widget.l10n.accountPageLinkEmailPasswordConfirmAction,
            showSubmitButton: false,
            isLoading: _isSubmitting,
            onSubmitCredentials: widget.onSubmitCredentials,
          ),
          if (_submitError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: AppSizes.inlineProgressIndicator,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                  ),
                )
              : Text(widget.l10n.accountPageLinkEmailPasswordConfirmAction),
        ),
      ],
    );
  }
}
