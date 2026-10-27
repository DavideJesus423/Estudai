import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';

/// Atalho de DESENVOLVIMENTO: entra no app sem conta, para navegar pelas
/// próximas telas enquanto não há autenticação real.
/// Aparece apenas em builds de debug (`kDebugMode`); remova quando o login
/// real estiver pronto.
class DemoModeButton extends StatelessWidget {
  const DemoModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.hint,
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: const Text('Entrar em modo demonstração (sem conta)'),
      ),
    );
  }
}
