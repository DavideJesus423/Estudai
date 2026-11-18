import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Opção de escolha única em formato de pílula (ex.: quantidade de questões).
/// `onTap` nulo desabilita a opção.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.fieldBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled || selected ? AppColors.navy : AppColors.hint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
