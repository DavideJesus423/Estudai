import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/back_label_button.dart';
import '../../shared/widgets/primary_button.dart';
import 'questions_repository.dart';
import 'quiz_screen.dart';
import 'widgets/choice_pill.dart';

/// Passo entre escolher o PDF e gerar: define quantas questões e quantas
/// alternativas cada uma terá. Ao gerar, troca esta tela pelo simulado.
class ConfigureQuestionsScreen extends StatefulWidget {
  const ConfigureQuestionsScreen({
    super.key,
    required this.filename,
    required this.bytes,
    required this.repository,
  });

  final String filename;
  final List<int> bytes;
  final QuestionsRepository repository;

  static const questionCounts = [5, 10, 15, 20];
  static const optionCounts = [4, 5];

  @override
  State<ConfigureQuestionsScreen> createState() => _ConfigureQuestionsScreenState();
}

class _ConfigureQuestionsScreenState extends State<ConfigureQuestionsScreen> {
  int _questionCount = 10;
  int _optionCount = 4;
  bool _loading = false;

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final questions = await widget.repository.generateFromPdf(
        bytes: widget.bytes,
        filename: widget.filename,
        numQuestions: _questionCount,
        numOptions: _optionCount,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => QuizScreen(title: widget.filename, questions: questions),
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackLabelButton(),
              const SizedBox(height: 8),
              const Text(
                'Configurar questões',
                style: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha como será o seu simulado.',
                style: TextStyle(fontSize: 16, color: AppColors.bodyText),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FileCard(name: widget.filename, size: _formatSize(widget.bytes.length)),
                      const SizedBox(height: 28),
                      _sectionLabel('Quantidade de questões'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final count in ConfigureQuestionsScreen.questionCounts)
                            ChoicePill(
                              label: '$count',
                              selected: _questionCount == count,
                              onTap: _loading ? null : () => setState(() => _questionCount = count),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('Alternativas por questão'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final count in ConfigureQuestionsScreen.optionCounts)
                            ChoicePill(
                              label: '$count alternativas',
                              selected: _optionCount == count,
                              onTap: _loading ? null : () => setState(() => _optionCount = count),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cada questão tem uma única alternativa correta e vem com explicação. '
                        'As questões são criadas por IA a partir do conteúdo do PDF.',
                        style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.hint),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navy),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lendo o material e criando as questões. Pode levar até um minuto.',
                        style: TextStyle(fontSize: 13, color: AppColors.hint),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                label: _loading ? 'Gerando questões...' : 'Gerar questões',
                onPressed: _loading ? null : _generate,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.name, required this.size});

  final String name;
  final String size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                Text(size, style: const TextStyle(fontSize: 13, color: AppColors.hint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
