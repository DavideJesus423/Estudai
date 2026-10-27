import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/materials/study_material.dart';

class EstudaApp extends StatelessWidget {
  const EstudaApp({
    super.key,
    this.authRepository = const UnconfiguredAuthRepository(),
    this.materialsRepository = const DemoMaterialsRepository(),
  });

  /// Serviço de autenticação. Enquanto nenhum serviço real estiver
  /// configurado, o padrão é [UnconfiguredAuthRepository].
  final AuthRepository authRepository;

  /// Materiais do usuário. Por ora, apenas dados de demonstração.
  final MaterialsRepository materialsRepository;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(
      authRepository: authRepository,
      materialsRepository: materialsRepository,
    );
    return MaterialApp(
      title: 'Estuda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
