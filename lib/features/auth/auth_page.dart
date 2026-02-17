import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/features/auth/widgets/login_form.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({required this.initialMode, super.key});

  final AuthMode initialMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool _isLoginMode;

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.initialMode == AuthMode.login;
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _isLoginMode ? l10n.login : l10n.register;
    final switchLabel = _isLoginMode
        ? l10n.authSwitchToRegister
        : l10n.authSwitchToLogin;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoginMode)
                      const LoginForm()
                    else
                      const RegisterForm(),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _toggleMode,
                      child: Text(switchLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
