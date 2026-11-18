import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'generated_question.dart';
import 'quiz_result_screen.dart';
import 'widgets/answer_option_tile.dart';

/// Resolve as questões uma por vez: escolher, confirmar, ver a explicação
/// e seguir. Ao terminar, troca esta tela pelo resultado.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.title, required this.questions});

  final String title;
  final List<GeneratedQuestion> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _scroll = ScrollController();
  late final List<int?> _answers = List<int?>.filled(widget.questions.length, null);
  int _index = 0;
  int? _selected;
  bool _confirmed = false;

  GeneratedQuestion get _question => widget.questions[_index];
  bool get _isLast => _index == widget.questions.length - 1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(int option) {
    if (_confirmed) return;
    setState(() => _selected = option);
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null || _confirmed) return;
    setState(() {
      _confirmed = true;
      _answers[_index] = selected;
    });
    // Leva o feedback para a área visível em telas pequenas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _next() {
    if (!_confirmed) return;
    if (_isLast) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => QuizResultScreen(
          title: widget.title,
          questions: widget.questions,
          answers: List<int?>.from(_answers),
        ),
      ));
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _confirmed = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do simulado?'),
        content: const Text('Seu progresso nesta rodada será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _requestExit() async {
    if (await _confirmExit() && mounted) Navigator.of(context).pop();
  }

  AnswerOptionState _stateOf(int option) {
    if (!_confirmed) {
      return option == _selected ? AnswerOptionState.selected : AnswerOptionState.idle;
    }
    if (option == _question.correctIndex) return AnswerOptionState.correct;
    if (option == _selected) return AnswerOptionState.wrong;
    return AnswerOptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final progress = (_index + (_confirmed ? 1 : 0)) / total;
    final primaryLabel = !_confirmed ? 'Confirmar' : (_isLast ? 'Ver resultado' : 'Próxima questão');
    final VoidCallback? primaryAction = !_confirmed ? (_selected == null ? null : _confirm) : _next;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _requestExit,
                      tooltip: 'Sair do simulado',
                      icon: const Icon(Icons.close, color: AppColors.navy),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Questão ${_index + 1} de $total',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Semantics(
                  label: 'Progresso: questão ${_index + 1} de $total',
                  excludeSemantics: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: progress),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.primarySoft,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_index),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _question.statement,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (var i = 0; i < _question.options.length; i++) ...[
                              AnswerOptionTile(
                                letter: optionLetter(i),
                                text: _question.options[i],
                                state: _stateOf(i),
                                onTap: _confirmed ? null : () => _select(i),
                              ),
                              const SizedBox(height: 10),
                            ],
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.topCenter,
                              child: _confirmed
                                  ? _FeedbackPanel(
                                      correct: _selected == _question.correctIndex,
                                      correctLetter: optionLetter(_question.correctIndex),
                                      explanation: _question.explanation,
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: primaryLabel, onPressed: primaryAction),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.correct,
    required this.correctLetter,
    required this.explanation,
  });

  final bool correct;
  final String correctLetter;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? AppColors.successSoft : AppColors.errorSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Resposta correta!' : 'Resposta incorreta',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
                ),
                if (!correct) ...[
                  const SizedBox(height: 2),
                  Text(
                    'A alternativa correta é a $correctLetter.',
                    style: const TextStyle(fontSize: 14, color: AppColors.bodyText),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  explanation,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
