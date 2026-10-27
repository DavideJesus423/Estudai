import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Campo de formulário com rótulo acima e borda discreta.
/// Com [isPassword], mostra "Mostrar"/"Ocultar" à direita para alternar
/// entre texto oculto e visível.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hideText = widget.isPassword && _obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: hideText,
          enableSuggestions: !widget.isPassword,
          autocorrect: !widget.isPassword,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(fontSize: 16, color: AppColors.bodyText),
          decoration: InputDecoration(
            errorText: widget.errorText,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: _border(AppColors.fieldBorder),
            focusedBorder: _border(AppColors.navy, 1.5),
            errorBorder: _border(Colors.red.shade700),
            focusedErrorBorder: _border(Colors.red.shade700, 1.5),
            suffixIconConstraints:
                const BoxConstraints(minHeight: 40, minWidth: 0),
            suffixIcon: widget.isPassword
                ? TextButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.hint,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: Text(_obscure ? 'Mostrar' : 'Ocultar'),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
