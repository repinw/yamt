import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

class EmailPasswordCredentialsForm extends StatefulWidget {
  const EmailPasswordCredentialsForm({
    super.key,
    required this.onSubmitCredentials,
    this.submitLabel,
    this.showSubmitButton = true,
    this.isLoading = false,
  });

  final Future<void> Function({required String email, required String password})
  onSubmitCredentials;

  final String? submitLabel;
  final bool showSubmitButton;
  final bool isLoading;

  @override
  State<EmailPasswordCredentialsForm> createState() =>
      EmailPasswordCredentialsFormState();
}

class EmailPasswordCredentialsFormState
    extends State<EmailPasswordCredentialsForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.onSubmitCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = widget.isLoading || _isSubmitting;
    final validators = AuthValidationFactory.fromContext(context);
    final emailValidator = validators.email();
    final passwordValidator = validators.password();
    final confirmPasswordValidator = validators.confirmPassword(
      passwordController: _passwordController,
      mismatchMessage: l10n.validationPasswordsDoNotMatch,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthEmailField(
            controller: _emailController,
            validator: emailValidator,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPasswordField(
            controller: _passwordController,
            validator: passwordValidator,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPasswordField(
            controller: _confirmPasswordController,
            label: l10n.confirmPasswordLabel,
            textInputAction: TextInputAction.done,
            validator: confirmPasswordValidator,
          ),
          if (widget.showSubmitButton) ...[
            const SizedBox(height: AppSpacing.xxl),
            AuthSubmitButton(
              isLoading: isLoading,
              onPressed: submit,
              label: widget.submitLabel ?? l10n.createAccount,
            ),
          ],
        ],
      ),
    );
  }
}
