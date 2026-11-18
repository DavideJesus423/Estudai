import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/materials/study_material.dart';
import 'features/questions/questions_repository.dart';

class EstudaApp extends StatelessWidget {
  const EstudaApp({
    super.key,
    this.authRepository = const ApiAuthRepository(),
    this.materialsRepository = const DemoMaterialsRepository(),
    this.questionsRepository = const ApiQuestionsRepository(),
  });

  final AuthRepository authRepository;
  final MaterialsRepository materialsRepository;
  final QuestionsRepository questionsRepository;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(
      authRepository: authRepository,
      materialsRepository: materialsRepository,
      questionsRepository: questionsRepository,
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
