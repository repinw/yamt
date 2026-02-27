import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({
    super.key,
    this.onSubmitCredentials,
    this.submitLabel,
    this.showSubmitButton = true,
  });

  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSubmitCredentials;

  final String? submitLabel;
  final bool showSubmitButton;

  @override
  ConsumerState<RegisterForm> createState() => RegisterFormState();
}

class RegisterFormState extends ConsumerState<RegisterForm> {
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

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final onSubmitCredentials = widget.onSubmitCredentials;
    if (onSubmitCredentials != null) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        await onSubmitCredentials(
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
      return;
    }

    await ref
        .read(authFormControllerProvider.notifier)
        .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  Future<void> submit() => _submit();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controllerLoading = ref.watch(authFormControllerProvider).isLoading;
    final isLoading = widget.onSubmitCredentials == null
        ? controllerLoading
        : _isSubmitting;
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
              onPressed: _submit,
              label: widget.submitLabel ?? l10n.createAccount,
            ),
          ],
        ],
      ),
    );
  }
}
