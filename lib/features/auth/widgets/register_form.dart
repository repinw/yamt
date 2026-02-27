import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/shared/widgets/email_password_credentials_form.dart';

class RegisterForm extends ConsumerWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authFormControllerProvider).isLoading;

    return EmailPasswordCredentialsForm(
      isLoading: isLoading,
      onSubmitCredentials: ({required email, required password}) async {
        await ref
            .read(authFormControllerProvider.notifier)
            .createUserWithEmailAndPassword(email: email, password: password);
      },
    );
  }
}
