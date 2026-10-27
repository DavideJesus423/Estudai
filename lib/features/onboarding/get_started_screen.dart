import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'widgets/study_material_card.dart';

typedef _Material = ({String subject, String title, Color color});

/// Tela de apresentação: grade de materiais, logo, título e botões de acesso.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  static const List<_Material> _materials = [
    (subject: 'CÁLCULO I', title: 'Resumo P2', color: AppColors.cardBlue),
    (subject: 'REDES', title: 'Slides aula 04', color: AppColors.cardGreen),
    (subject: 'BANCOS', title: 'Apostila SQL', color: AppColors.cardYellow),
    (subject: 'ENG.SW', title: 'Requisitos', color: AppColors.cardRed),
    (subject: 'GESTÃO', title: 'Escopo e PI', color: AppColors.cardMagenta),
    (subject: 'SEGURANÇA', title: 'XSS- Notas', color: AppColors.cardMagenta),
  ];

  // Cartão 89x124 e espaço horizontal de ~37,5 no frame de 390 de largura.
  static const double _cardAspect = 89 / 124;

  Widget _gridRow(List<_Material> items) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            flex: 178,
            child: AspectRatio(
              aspectRatio: _cardAspect,
              child: StudyMaterialCard(
                subject: items[i].subject,
                title: items[i].title,
                color: items[i].color,
              ),
            ),
          ),
          if (i < items.length - 1)
            const Expanded(flex: 75, child: SizedBox.shrink()),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _gridRow(_materials.sublist(0, 3)),
                    const SizedBox(height: 13),
                    _gridRow(_materials.sublist(3, 6)),
                    const SizedBox(height: 32),
                    const Spacer(),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 62,
                      semanticLabel: 'Logo do aplicativo',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Transforme seu material\nem questões',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Envie seus PDFs e pratique com questões geradas por IA.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Começar agora',
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.navy,
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.signUp),
                    ),
                    const SizedBox(height: 9),
                    PrimaryButton(
                      label: 'Entrar',
                      backgroundColor: AppColors.secondarySoft,
                      foregroundColor: AppColors.navy,
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.login),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
