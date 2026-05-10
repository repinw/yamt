import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines login form.
class LoginForm extends ConsumerStatefulWidget {
  /// The login form.
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    await ref
        .read(authFormControllerProvider.notifier)
        .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  void _showForgotPasswordNotice() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.commonNotImplementedYet)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authFormControllerProvider).isLoading;
    final validators = AuthValidationFactory.fromContext(context);
    final emailValidator = validators.email();
    final passwordValidator = validators.password();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            textInputAction: TextInputAction.done,
            validator: passwordValidator,
            showLabel: false,
            showVisibilityToggle: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            fieldKey: const Key('auth_password_field'),
            placeholder: l10n.passwordLabel,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('auth_forgot_password_button'),
              onPressed: _showForgotPasswordNotice,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.authForgotPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AuthSubmitButton(
            isLoading: isLoading,
            onPressed: _submit,
            buttonKey: const Key('auth_login_submit_button'),
            label: l10n.login,
            trailingIcon: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
