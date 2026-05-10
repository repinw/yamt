import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shared/widgets/email_password_credentials_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines link email password dialog.
class LinkEmailPasswordDialog extends StatefulWidget {
  /// The link email password dialog.
  const LinkEmailPasswordDialog({
    required this.l10n,
    required this.onSubmitCredentials,
    required this.errorMessageFor,
    super.key,
    this.shouldBubbleSubmitError,
  });

  /// The l10n.
  final AppLocalizations l10n;

  /// Documented member.
  final Future<void> Function({required String email, required String password})
  onSubmitCredentials;

  /// The error message for.
  final String Function(Object error) errorMessageFor;

  /// Whether bubble submit error.
  final bool Function(Object error)? shouldBubbleSubmitError;

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

    final didSubmit =
        await (_formKey.currentState?.submit() ?? Future.value(false));
    if (!mounted) {
      return;
    }
    if (!didSubmit) {
      final submitError = _formKey.currentState?.lastSubmitError;
      if (submitError != null) {
        final shouldBubble = widget.shouldBubbleSubmitError?.call(submitError);
        if (shouldBubble ?? false) {
          Navigator.of(context).pop(submitError);
          return;
        }
        setState(() {
          _submitError = widget.errorMessageFor(submitError);
          _isSubmitting = false;
        });
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _clearSubmitError() {
    if (_submitError == null) {
      return;
    }
    setState(() {
      _submitError = null;
    });
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
            onInputChanged: _clearSubmitError,
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
