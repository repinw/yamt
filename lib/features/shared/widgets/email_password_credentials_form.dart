import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines email password credentials form.
class EmailPasswordCredentialsForm extends StatefulWidget {
  /// The email password credentials form.
  const EmailPasswordCredentialsForm({
    super.key,
    required this.onSubmitCredentials,
    this.submitLabel,
    this.showSubmitButton = true,
    this.isLoading = false,
    this.onInputChanged,
  });

  /// Documented member.
  final Future<void> Function({required String email, required String password})
  onSubmitCredentials;

  /// The submit label.
  final String? submitLabel;

  /// The show submit button.
  final bool showSubmitButton;

  /// Whether loading.
  final bool isLoading;

  /// The on input changed.
  final VoidCallback? onInputChanged;

  @override
  State<EmailPasswordCredentialsForm> createState() =>
      EmailPasswordCredentialsFormState();
}

/// Defines email password credentials form state.
class EmailPasswordCredentialsFormState
    extends State<EmailPasswordCredentialsForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Object? _lastSubmitError;

  /// The last submit error.
  Object? get lastSubmitError => _lastSubmitError;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Submit.
  Future<bool> submit() async {
    if (widget.isLoading) {
      return false;
    }
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      _lastSubmitError = null;
      return false;
    }

    _lastSubmitError = null;
    try {
      await widget.onSubmitCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      return true;
    } catch (error) {
      _lastSubmitError = error;
      return false;
    }
  }

  void _onSubmitPressed() {
    unawaited(submit());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = widget.isLoading;
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
            onChanged: (_) => widget.onInputChanged?.call(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPasswordField(
            controller: _passwordController,
            validator: passwordValidator,
            onChanged: (_) => widget.onInputChanged?.call(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPasswordField(
            controller: _confirmPasswordController,
            label: l10n.confirmPasswordLabel,
            textInputAction: TextInputAction.done,
            validator: confirmPasswordValidator,
            onChanged: (_) => widget.onInputChanged?.call(),
          ),
          if (widget.showSubmitButton) ...[
            const SizedBox(height: AppSpacing.xxl),
            AuthSubmitButton(
              isLoading: isLoading,
              onPressed: _onSubmitPressed,
              label: widget.submitLabel ?? l10n.createAccount,
            ),
          ],
        ],
      ),
    );
  }
}
