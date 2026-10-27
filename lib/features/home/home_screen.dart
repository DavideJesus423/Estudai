import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../materials/study_material.dart';
import '../onboarding/widgets/study_material_card.dart';

/// Início: biblioteca de materiais do estudante.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.materialsRepository});

  final MaterialsRepository materialsRepository;

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                  Image.asset('assets/images/logo.png',
                      height: 44, semanticLabel: 'Logo do Estuda'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.getStarted, (_) => false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Sair'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Seus materiais',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha um material para praticar.',
                style: TextStyle(fontSize: 16, color: AppColors.bodyText),
              ),
              if (materialsRepository.isDemo) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Modo demonstração: materiais de exemplo.',
                    style: TextStyle(fontSize: 13, color: AppColors.navy),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: materials.isEmpty
                    ? const _EmptyLibrary()
                    : GridView.builder(
                        itemCount: materials.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                onPressed: () => _comingSoon(
                    context, 'O envio de PDF será a próxima etapa.'),
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
