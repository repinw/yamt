import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

class EmailPasswordCredentials {
  const EmailPasswordCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class LinkEmailPasswordDialog extends StatefulWidget {
  const LinkEmailPasswordDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<LinkEmailPasswordDialog> createState() =>
      _LinkEmailPasswordDialogState();
}

class _LinkEmailPasswordDialogState extends State<LinkEmailPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    Navigator.of(context).pop(
      EmailPasswordCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final emailValidator = buildEmailValidator(context);
    final passwordValidator = buildPasswordValidator(context);
    final confirmValidator = buildConfirmPasswordValidator(
      _passwordController,
      context,
      mismatchMessage: l10n.validationPasswordsDoNotMatch,
    );

    return AlertDialog(
      title: Text(l10n.accountPageLinkEmailPasswordTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.accountPageLinkEmailPasswordDescription),
            const SizedBox(height: AppSpacing.md),
            AuthEmailField(
              controller: _emailController,
              validator: emailValidator,
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthPasswordField(
              controller: _passwordController,
              validator: passwordValidator,
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthPasswordField(
              controller: _confirmPasswordController,
              label: l10n.confirmPasswordLabel,
              textInputAction: TextInputAction.done,
              validator: confirmValidator,
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
          child: Text(l10n.accountPageLinkEmailPasswordConfirmAction),
        ),
      ],
    );
  }
}
