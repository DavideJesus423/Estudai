import 'package:flutter/material.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/materials/study_material.dart';
import '../../features/onboarding/get_started_screen.dart';
import '../../features/questions/questions_repository.dart';
import '../../features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String getStarted = '/get-started';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String home = '/home';
}

class AppRouter {
  const AppRouter({
    required this.authRepository,
    required this.materialsRepository,
    required this.questionsRepository,
  });

  final AuthRepository authRepository;
  final MaterialsRepository materialsRepository;
  final QuestionsRepository questionsRepository;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.getStarted:
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const GetStartedScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      case AppRoutes.login:
        return _page(settings, LoginScreen(authRepository: authRepository));
      case AppRoutes.signUp:
        return _page(settings, SignUpScreen(authRepository: authRepository));
      case AppRoutes.home:
        return _page(
          settings,
          HomeScreen(
            materialsRepository: materialsRepository,
            questionsRepository: questionsRepository,
            authRepository: authRepository,
          ),
        );
      case AppRoutes.splash:
      default:
        return _page(settings, const SplashScreen());
    }
  }

  MaterialPageRoute<void> _page(RouteSettings settings, Widget page) {
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
