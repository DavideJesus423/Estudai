import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.subject,
    required this.title,
    required this.color,
  });

  final String id;
  final String subject;
  final String title;
  final Color color;
}

/// Fonte dos materiais do usuário. Hoje só existe a versão de demonstração;
/// depois será trocada por uma que lê os PDFs enviados (e a API/backend).
abstract class MaterialsRepository {
  List<StudyMaterial> list();

  /// `true` quando os dados são de exemplo e não do usuário.
  bool get isDemo;
}

class DemoMaterialsRepository implements MaterialsRepository {
  const DemoMaterialsRepository();

  @override
  bool get isDemo => true;

  @override
  List<StudyMaterial> list() => const [
        StudyMaterial(id: '1', subject: 'CÁLCULO I', title: 'Resumo P2', color: AppColors.cardBlue),
        StudyMaterial(id: '2', subject: 'REDES', title: 'Slides aula 04', color: AppColors.cardGreen),
        StudyMaterial(id: '3', subject: 'BANCOS', title: 'Apostila SQL', color: AppColors.cardYellow),
        StudyMaterial(id: '4', subject: 'ENG.SW', title: 'Requisitos', color: AppColors.cardRed),
        StudyMaterial(id: '5', subject: 'GESTÃO', title: 'Escopo e PI', color: AppColors.cardMagenta),
        StudyMaterial(id: '6', subject: 'SEGURANÇA', title: 'XSS- Notas', color: AppColors.cardMagenta),
      ];
}
