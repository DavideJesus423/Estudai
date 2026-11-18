import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Letra da alternativa: 0 vira "A", 1 vira "B" e assim por diante.
String optionLetter(int index) => String.fromCharCode(65 + index);

enum AnswerOptionState { idle, selected, correct, wrong, dimmed }

/// Alternativa de uma questão. O estado é indicado por cor, ícone e texto
/// para leitores de tela, para não depender só da cor.
class AnswerOptionTile extends StatelessWidget {
  const AnswerOptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final AnswerOptionState state;

  /// `null` deixa a alternativa travada (depois de confirmar a resposta).
  final VoidCallback? onTap;

  String get _semanticsSuffix {
    switch (state) {
      case AnswerOptionState.correct:
        return '. Resposta correta';
      case AnswerOptionState.wrong:
        return '. Sua resposta, incorreta';
      case AnswerOptionState.selected:
        return '. Selecionada';
      case AnswerOptionState.idle:
      case AnswerOptionState.dimmed:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    final Color badge;
    final Color textColor;
    Widget badgeChild = Text(
      letter,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
    );
    var borderWidth = 1.0;

    switch (state) {
      case AnswerOptionState.selected:
        background = AppColors.primarySoft;
        border = AppColors.navy;
        badge = Colors.white;
        textColor = AppColors.navy;
        borderWidth = 1.5;
        break;
      case AnswerOptionState.correct:
        background = AppColors.successSoft;
        border = AppColors.success;
        badge = AppColors.success;
        textColor = AppColors.bodyText;
        borderWidth = 1.5;
        badgeChild = const Icon(Icons.check, size: 18, color: Colors.white);
        break;
      case AnswerOptionState.wrong:
        background = AppColors.errorSoft;
        border = AppColors.error;
        badge = AppColors.error;
        textColor = AppColors.bodyText;
        borderWidth = 1.5;
        badgeChild = const Icon(Icons.close, size: 18, color: Colors.white);
        break;
      case AnswerOptionState.dimmed:
        background = Colors.white;
        border = AppColors.fieldBorder.withAlpha(110);
        badge = AppColors.secondarySoft;
        textColor = AppColors.hint;
        break;
      case AnswerOptionState.idle:
        background = Colors.white;
        border = AppColors.fieldBorder;
        badge = AppColors.secondarySoft;
        textColor = AppColors.bodyText;
        break;
    }

    return Semantics(
      button: onTap != null,
      label: 'Alternativa $letter: $text$_semanticsSuffix',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: borderWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
                  child: badgeChild,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 16, height: 1.35, color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
