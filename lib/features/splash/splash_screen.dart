import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

/// Tela de abertura: logo centralizada em fundo branco.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration displayTime = Duration(milliseconds: 1800);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.displayTime, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.getStarted);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 119,
          semanticLabel: 'Logo do aplicativo',
        ),
      ),
    );
  }
}
