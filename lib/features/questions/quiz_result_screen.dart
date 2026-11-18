import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'generated_question.dart';
import 'quiz_screen.dart';
import 'widgets/answer_option_tile.dart';
import 'widgets/score_ring.dart';

/// Resultado do simulado: aproveitamento, acertos e erros, ações e a revisão
/// de cada questão com a explicação.
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.answers,
  });

  final String title;
  final List<GeneratedQuestion> questions;

  /// Alternativa escolhida em cada questão (mesma ordem de [questions]).
  final List<int?> answers;

  bool _isCorrect(int i) => answers[i] == questions[i].correctIndex;

  String _headline(double ratio) {
    if (ratio >= 0.9) return 'Excelente!';
    if (ratio >= 0.7) return 'Muito bem!';
    if (ratio >= 0.5) return 'Bom começo!';
    return 'Vale revisar o conteúdo';
  }

  void _retry(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => QuizScreen(title: title, questions: questions),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = questions.length;
    final hits = List.generate(total, _isCorrect).where((ok) => ok).length;
    final ratio = total == 0 ? 0.0 : hits / total;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: ScoreRing(value: ratio)),
              const SizedBox(height: 24),
              Text(
                _headline(ratio),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              Text(
                'Você acertou $hits de $total questões.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.bodyText),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.hint),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Acertos',
                      value: hits,
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      background: AppColors.successSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Erros',
                      value: total - hits,
                      icon: Icons.cancel,
                      color: AppColors.error,
                      background: AppColors.errorSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Refazer questões', onPressed: () => _retry(context)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Voltar ao início',
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.navy,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              const SizedBox(height: 32),
              const Text(
                'Revisar respostas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < total; i++)
                _ReviewTile(
                  number: i + 1,
                  question: questions[i],
                  answer: answers[i],
                  correct: _isCorrect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.bodyText)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.answer,
    required this.correct,
  });

  final int number;
  final GeneratedQuestion question;
  final int? answer;
  final bool correct;

  String _optionText(int index) => '${optionLetter(index)}) ${question.options[index]}';

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 14, height: 1.4, color: AppColors.bodyText);
    final picked = answer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: correct ? AppColors.success : AppColors.error,
          ),
          title: Text(
            '$number. ${question.statement}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy),
          ),
          children: [
            Text(question.statement, style: bodyStyle.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (!correct)
              Text(
                picked == null ? 'Sem resposta.' : 'Sua resposta: ${_optionText(picked)}',
                style: bodyStyle.copyWith(color: AppColors.error),
              ),
            Text(
              'Correta: ${_optionText(question.correctIndex)}',
              style: bodyStyle.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(question.explanation, style: bodyStyle),
          ],
        ),
      ),
    );
  }
}
