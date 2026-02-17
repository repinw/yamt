import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/widgets/auth_form_components.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    final auth = ref.read(firebaseAuthProvider);

    try {
      await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      context.go(AppRoutes.welcome);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = error.message ?? AppLocalizations.of(context)!.authFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emailValidator = buildEmailValidator(context);
    final passwordValidator = buildPasswordValidator(context);
    final confirmPasswordValidator = buildConfirmPasswordValidator(
      _passwordController,
      context,
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
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _passwordController,
            validator: passwordValidator,
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _confirmPasswordController,
            label: l10n.confirmPasswordLabel,
            textInputAction: TextInputAction.done,
            validator: confirmPasswordValidator,
          ),
          const SizedBox(height: 20),
          AuthSubmitButton(
            isLoading: _isLoading,
            onPressed: _submit,
            label: l10n.createAccount,
          ),
        ],
      ),
    );
  }
}
