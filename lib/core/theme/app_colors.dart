import 'package:flutter/material.dart';

/// Cores medidas diretamente nas telas do Figma (frame 390x844).
abstract final class AppColors {
  /// Títulos, rótulos e texto de destaque.
  static const Color navy = Color(0xFF04324C);

  /// Botão "Começar agora".
  static const Color primarySoft = Color(0xFFC7DBFC);

  /// Botão "Entrar" (Get Started).
  static const Color secondarySoft = Color(0xFFF1F5F4);

  /// Botão "Entrar com e-mail" no estado desabilitado.
  static const Color disabled = Color(0xFF8098A4);

  static const Color fieldBorder = Color(0xFF9AA0A2);

  /// Texto "Mostrar" e dicas.
  static const Color hint = Color(0xFF6B7478);

  static const Color bodyText = Color(0xFF1A1A1A);
  static const Color google = Color(0xFF4286F4);

  // Cartões de materiais (pastel).
  static const Color cardBlue = Color(0xFFAEC2FF);
  static const Color cardGreen = Color(0xFF8DFF98);
  static const Color cardYellow = Color(0xFFFFF9A9);
  static const Color cardRed = Color(0xFFFFC2C2);
  static const Color cardMagenta = Color(0xFFF395FF);
}
