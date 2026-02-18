import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

class LoginForm extends ConsumerStatefulWidget {
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
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _passwordController,
            textInputAction: TextInputAction.done,
            validator: passwordValidator,
          ),
          const SizedBox(height: 20),
          AuthSubmitButton(
            isLoading: isLoading,
            onPressed: _submit,
            label: l10n.login,
          ),
        ],
      ),
    );
  }
}
