import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines email password credentials form.
class EmailPasswordCredentialsForm extends StatefulWidget {
  /// The email password credentials form.
  const new({
    required this.onSubmitCredentials,
    super.key,
    this.isLoading = false,
    this.onInputChanged,
  });

  /// Documented member.
  final Future<void> Function({required String email, required String password})
  onSubmitCredentials;

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
    } on Object catch (error) {
      _lastSubmitError = error;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validators = AuthValidationFactory.fromContext(context);
    final emailValidator = validators.email();
    final passwordValidator = validators.password();
    final confirmPasswordValidator = validators.confirmPassword(
      passwordController: _passwordController,
      mismatchMessage: l10n.validationPasswordsDoNotMatch,
    );

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthEmailField(
              controller: _emailController,
              validator: emailValidator,
              onChanged: (_) => widget.onInputChanged?.call(),
              showLabel: false,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              placeholder: l10n.emailLabel,
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthPasswordField(
              controller: _passwordController,
              validator: passwordValidator,
              onChanged: (_) => widget.onInputChanged?.call(),
              showLabel: false,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              placeholder: l10n.passwordLabel,
              showVisibilityToggle: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthPasswordField(
              controller: _confirmPasswordController,
              textInputAction: TextInputAction.done,
              validator: confirmPasswordValidator,
              onChanged: (_) => widget.onInputChanged?.call(),
              showLabel: false,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              placeholder: l10n.confirmPasswordLabel,
              showVisibilityToggle: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
          ],
        ),
      ),
    );
  }
}
