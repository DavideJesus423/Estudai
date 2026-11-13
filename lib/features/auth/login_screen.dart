import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/back_label_button.dart';
import '../../shared/widgets/google_logo.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_button.dart';
import 'auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  bool get _canSubmit =>
      !_loading && isValidEmail(_emailController.text) && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await action();
    } on AuthNotConfiguredException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submitEmail() {
    if (!_canSubmit) return;
    _run(() async {
      await widget.authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    });
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      _showMessage('Informe um e-mail válido para recuperar a senha.');
      return;
    }
    _run(() => widget.authRepository.sendPasswordReset(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 6),
                  const BackLabelButton(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entrar', style: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.navy)),
                        const SizedBox(height: 40),
                        AppTextField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Senha',
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submitEmail(),
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(label: 'Entrar com e-mail', onPressed: _canSubmit ? _submitEmail : null),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : _forgotPassword,
                            style: TextButton.styleFrom(foregroundColor: AppColors.navy, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            child: const Text('Esqueceu a sua senha?'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      children: [
                        SocialButton(
                          label: 'Continuar com Apple',
                          backgroundColor: Colors.black,
                          icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                          onPressed: _loading ? null : () => _run(widget.authRepository.signInWithApple),
                        ),
                        const SizedBox(height: 6),
                        SocialButton(
                          label: 'Continuar com Google',
                          backgroundColor: AppColors.google,
                          icon: const GoogleLogo(size: 22),
                          onPressed: _loading ? null : () => _run(widget.authRepository.signInWithGoogle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
