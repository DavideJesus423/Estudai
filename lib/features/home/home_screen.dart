import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../auth/auth_repository.dart';
import '../materials/study_material.dart';
import '../onboarding/widgets/study_material_card.dart';
import '../questions/configure_questions_screen.dart';
import '../questions/questions_repository.dart';

/// Início: biblioteca de materiais. Os materiais ainda são demonstração.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.materialsRepository,
    required this.questionsRepository,
    required this.authRepository,
  });

  final MaterialsRepository materialsRepository;
  final QuestionsRepository questionsRepository;
  final AuthRepository authRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Mesmo limite do backend (MAX_PDF_MB).
  static const _maxPdfBytes = 10 * 1024 * 1024;

  MaterialsRepository get materialsRepository => widget.materialsRepository;
  AuthRepository get authRepository => widget.authRepository;

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxPdfBytes) {
        _message('O PDF tem mais de 10 MB. Escolha um arquivo menor.');
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ConfigureQuestionsScreen(
          filename: file.name,
          bytes: bytes,
          repository: widget.questionsRepository,
        ),
      ));
    } catch (_) {
      if (mounted) _message('Não foi possível abrir o arquivo.');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await authRepository.signOut();
    } catch (error) {
      // O cliente apaga os tokens locais mesmo se a API estiver indisponível.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sessão local encerrada. Aviso: $error')),
        );
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.getStarted,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = materialsRepository.list();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 44, semanticLabel: 'Logo do Estuda'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _logout(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Sair'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Seus materiais',
                style: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              const Text('Escolha um material para praticar.', style: TextStyle(fontSize: 16, color: AppColors.bodyText)),
              if (materialsRepository.isDemo) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.secondarySoft, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Modo demonstração: materiais de exemplo.', style: TextStyle(fontSize: 13, color: AppColors.navy)),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: materials.isEmpty
                    ? const _EmptyLibrary()
                    : GridView.builder(
                        itemCount: materials.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 13,
                          childAspectRatio: 89 / 124,
                        ),
                        itemBuilder: (_, i) => StudyMaterialCard(
                          subject: materials[i].subject,
                          title: materials[i].title,
                          color: materials[i].color,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Enviar material',
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.navy,
                onPressed: _pickPdf,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum material ainda.\nEnvie seu primeiro PDF.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: AppColors.hint),
      ),
    );
  }
}
