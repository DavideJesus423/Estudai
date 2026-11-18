import 'package:estuda/core/theme/app_theme.dart';
import 'package:estuda/features/questions/configure_questions_screen.dart';
import 'package:estuda/features/questions/generated_question.dart';
import 'package:estuda/features/questions/questions_repository.dart';
import 'package:estuda/features/questions/quiz_result_screen.dart';
import 'package:estuda/features/questions/quiz_screen.dart';
import 'package:estuda/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _questions = [
  GeneratedQuestion(
    statement: 'Qual camada do modelo OSI cuida do roteamento?',
    options: ['Física', 'Enlace', 'Rede', 'Transporte'],
    correctIndex: 2,
    explanation: 'A camada de Rede faz o roteamento.',
  ),
  GeneratedQuestion(
    statement: 'Qual protocolo é orientado a conexão?',
    options: ['UDP', 'TCP', 'ICMP', 'ARP'],
    correctIndex: 1,
    explanation: 'O TCP estabelece conexão antes de enviar dados.',
  ),
];

class _FakeRepository implements QuestionsRepository {
  int calls = 0;
  int? numQuestions;
  int? numOptions;

  @override
  Future<List<GeneratedQuestion>> generateFromPdf({
    required List<int> bytes,
    required String filename,
    int numQuestions = 5,
    int numOptions = 4,
  }) async {
    calls++;
    this.numQuestions = numQuestions;
    this.numOptions = numOptions;
    return _questions;
  }
}

class _FailingRepository implements QuestionsRepository {
  @override
  Future<List<GeneratedQuestion>> generateFromPdf({
    required List<int> bytes,
    required String filename,
    int numQuestions = 5,
    int numOptions = 4,
  }) async {
    throw Exception('A API está fora do ar.');
  }
}

void _useIphoneSizedScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

void main() {
  testWidgets('configurar envia as escolhas e abre o simulado', (tester) async {
    _useIphoneSizedScreen(tester);
    final repository = _FakeRepository();
    await tester.pumpWidget(_app(ConfigureQuestionsScreen(
      filename: 'redes.pdf',
      bytes: List<int>.filled(2048, 1),
      repository: repository,
    )));

    expect(find.text('redes.pdf'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.tap(find.text('5 alternativas'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Gerar questões'));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.numQuestions, 5);
    expect(repository.numOptions, 5);
    expect(find.text('Questão 1 de 2'), findsOneWidget);
  });

  testWidgets('configurar mostra o erro e permite tentar de novo', (tester) async {
    _useIphoneSizedScreen(tester);
    await tester.pumpWidget(_app(ConfigureQuestionsScreen(
      filename: 'redes.pdf',
      bytes: List<int>.filled(10, 1),
      repository: _FailingRepository(),
    )));

    await tester.tap(find.widgetWithText(PrimaryButton, 'Gerar questões'));
    await tester.pumpAndSettle();

    expect(find.text('A API está fora do ar.'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Gerar questões'), findsOneWidget);
  });

  testWidgets('simulado: confirmar, ver explicação e chegar ao resultado', (tester) async {
    _useIphoneSizedScreen(tester);
    await tester.pumpWidget(_app(const QuizScreen(title: 'redes.pdf', questions: _questions)));

    final confirm = find.widgetWithText(PrimaryButton, 'Confirmar');
    expect(tester.widget<PrimaryButton>(confirm).onPressed, isNull);

    await tester.tap(find.text('Enlace'));
    await tester.pump();
    expect(tester.widget<PrimaryButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.text('Resposta incorreta'), findsOneWidget);
    expect(find.text('A alternativa correta é a C.'), findsOneWidget);
    expect(find.text('A camada de Rede faz o roteamento.'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Próxima questão'));
    await tester.pumpAndSettle();
    expect(find.text('Questão 2 de 2'), findsOneWidget);

    await tester.tap(find.text('TCP'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Resposta correta!'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Ver resultado'));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Você acertou 1 de 2 questões.'), findsOneWidget);
  });

  testWidgets('sair do simulado pede confirmação', (tester) async {
    _useIphoneSizedScreen(tester);
    await tester.pumpWidget(_app(const QuizScreen(title: 'redes.pdf', questions: _questions)));

    await tester.tap(find.byTooltip('Sair do simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do simulado?'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do simulado?'), findsNothing);
    expect(find.text('Questão 1 de 2'), findsOneWidget);
  });

  testWidgets('resultado: revisão mostra a resposta dada e a correta; voltar ao início', (tester) async {
    _useIphoneSizedScreen(tester);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const QuizResultScreen(
                  title: 'redes.pdf',
                  questions: _questions,
                  answers: [2, 0],
                ),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Você acertou 1 de 2 questões.'), findsOneWidget);
    expect(find.text('Acertos'), findsOneWidget);
    expect(find.text('Erros'), findsOneWidget);

    final secondReview = find.textContaining('2. Qual protocolo');
    await tester.ensureVisible(secondReview);
    await tester.tap(secondReview);
    await tester.pumpAndSettle();
    expect(find.text('Sua resposta: A) UDP'), findsOneWidget);
    expect(find.text('Correta: B) TCP'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Voltar ao início'));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('refazer volta para a primeira questão', (tester) async {
    _useIphoneSizedScreen(tester);
    await tester.pumpWidget(_app(const QuizResultScreen(
      title: 'redes.pdf',
      questions: _questions,
      answers: [2, 1],
    )));
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Excelente!'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Refazer questões'));
    await tester.pumpAndSettle();
    expect(find.text('Questão 1 de 2'), findsOneWidget);
  });
}
