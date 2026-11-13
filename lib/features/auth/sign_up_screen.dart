import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/back_label_button.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;
  static const int minPasswordLength = 8;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  bool get _passwordsMatch => _passwordController.text == _confirmController.text;
  bool get _canSubmit => !_loading &&
      _nameController.text.trim().length >= 2 &&
      isValidEmail(_emailController.text) &&
      _passwordController.text.length >= SignUpScreen.minPasswordLength &&
      _passwordsMatch;

  String? get _passwordError {
    final text = _passwordController.text;
    if (text.isEmpty || text.length >= SignUpScreen.minPasswordLength) return null;
    return 'Use pelo menos ${SignUpScreen.minPasswordLength} caracteres.';
  }

  String? get _confirmError {
    if (_confirmController.text.isEmpty || _passwordsMatch) return null;
    return 'As senhas não coincidem.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await widget.authRepository.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } on AuthNotConfiguredException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    padding: const EdgeInsets.fromLTRB(25, 20, 25, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Criar conta', style: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.navy)),
                        const SizedBox(height: 32),
                        AppTextField(
                          label: 'Nome completo',
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Senha',
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          errorText: _passwordError,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Confirmar senha',
                          controller: _confirmController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          errorText: _confirmError,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(label: 'Criar conta', onPressed: _canSubmit ? _submit : null),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                            style: TextButton.styleFrom(foregroundColor: AppColors.navy, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            child: const Text('Já tenho conta'),
                          ),
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
