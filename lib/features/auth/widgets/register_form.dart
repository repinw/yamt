import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines register form.
class RegisterForm extends ConsumerStatefulWidget {
  /// The register form.
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    await ref
        .read(authFormControllerProvider.notifier)
        .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );
  }

  String? _validateDisplayName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.authGuestNameRequiredError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authFormControllerProvider).isLoading;
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
          AuthTextField(
            controller: _displayNameController,
            validator: (value) => _validateDisplayName(value, l10n),
            label: l10n.authGuestNameFieldLabel,
            showLabel: false,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            fieldKey: const Key('auth_display_name_field'),
            placeholder: l10n.authGuestNameFieldLabel,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthEmailField(
            controller: _emailController,
            validator: emailValidator,
            showLabel: false,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            fieldKey: const Key('auth_email_field'),
            placeholder: l10n.emailLabel,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPasswordField(
            controller: _passwordController,
            validator: passwordValidator,
            showLabel: false,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            fieldKey: const Key('auth_password_field'),
            placeholder: l10n.passwordLabel,
            showVisibilityToggle: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPasswordField(
            controller: _confirmPasswordController,
            label: l10n.confirmPasswordLabel,
            textInputAction: TextInputAction.done,
            validator: confirmPasswordValidator,
            showLabel: false,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            fieldKey: const Key('auth_confirm_password_field'),
            placeholder: l10n.confirmPasswordLabel,
            showVisibilityToggle: true,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AuthSubmitButton(
            isLoading: isLoading,
            onPressed: _submit,
            buttonKey: const Key('auth_register_submit_button'),
            label: l10n.createAccount,
          ),
        ],
      ),
    );
  }
}
