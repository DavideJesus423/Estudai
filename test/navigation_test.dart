import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda/app.dart';
import 'package:estuda/features/splash/splash_screen.dart';
import 'package:estuda/shared/widgets/primary_button.dart';

void _useIphoneSizedScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _goToGetStarted(WidgetTester tester) async {
  await tester.pumpWidget(const EstudaApp());
  expect(find.byType(SplashScreen), findsOneWidget);
  await tester.pump(SplashScreen.displayTime);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('splash leva para Get Started', (tester) async {
    _useIphoneSizedScreen(tester);
    await _goToGetStarted(tester);

    expect(find.textContaining('Transforme seu material'), findsOneWidget);
    expect(find.text('Começar agora'), findsOneWidget);
    expect(find.text('CÁLCULO I'), findsOneWidget);
  });

  testWidgets('Entrar abre o login e Back retorna', (tester) async {
    _useIphoneSizedScreen(tester);
    await _goToGetStarted(tester);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar com Apple'), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Começar agora'), findsOneWidget);
  });

  testWidgets('senha alterna entre Mostrar e Ocultar', (tester) async {
    _useIphoneSizedScreen(tester);
    await _goToGetStarted(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Entrar'));
    await tester.pumpAndSettle();

    TextField passwordField() => tester.widget<TextField>(find.byType(TextField).last);

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.text('Mostrar'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    expect(find.text('Ocultar'), findsOneWidget);
  });

  testWidgets('login não simula sucesso: avisa que não está configurado',
      (tester) async {
    _useIphoneSizedScreen(tester);
    await _goToGetStarted(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Entrar'));
    await tester.pumpAndSettle();

    // Botão começa desabilitado.
    final button = find.widgetWithText(PrimaryButton, 'Entrar com e-mail');
    expect(tester.widget<PrimaryButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'aluno@exemplo.com');
    await tester.enterText(find.byType(TextField).last, 'umasenha');
    await tester.pump();
    expect(tester.widget<PrimaryButton>(button).onPressed, isNotNull);

    await tester.tap(button);
    await tester.pump();
    await tester.pump();
    expect(find.text('Login por e-mail ainda não está configurado.'),
        findsOneWidget);
  });

  testWidgets('Começar agora abre a tela de cadastro (proposta)',
      (tester) async {
    _useIphoneSizedScreen(tester);
    await _goToGetStarted(tester);

    await tester.tap(find.text('Começar agora'));
    await tester.pumpAndSettle();
    expect(find.text('Criar conta'), findsWidgets);
    expect(find.text('Confirmar senha'), findsOneWidget);
  });

  testWidgets('modo demonstração (debug) leva à tela Início', (tester) async {
    _useIphoneSizedScreen(tester);
    await _goToGetStarted(tester);

    await tester.tap(find.text('Começar agora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar em modo demonstração (sem conta)'));
    await tester.pumpAndSettle();

    expect(find.text('Seus materiais'), findsOneWidget);
    expect(find.text('Modo demonstração: materiais de exemplo.'), findsOneWidget);
    expect(find.text('Enviar material'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Começar agora'), findsOneWidget);
  });
}
