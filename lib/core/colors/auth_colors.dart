import 'package:flutter/material.dart';

/// Paleta de cores específica para os fluxos de autenticação.
///
/// Mantida separada do [AppColors] principal para facilitar theming
/// independente da tela de login/cadastro sem impactar o restante do app.
class AuthColors {
  AuthColors._();

  /// Cor dos links de ação secundária (ex: "Esqueci minha senha", "Cadastre-se").
  /// Hex: #00ACC1 — Cyan 600 do Material Design.
  static const Color tealLink = Color(0xFF00ACC1);

  /// Gradiente do botão principal de ação.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF4DB6AC), // Teal 300
      Color(0xFF2E7D32), // Green 800
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Cor da sombra do botão principal (translúcida).
  static const Color buttonShadow = Color(0x734DB6AC);

  /// Cor da borda padrão dos campos de input.
  static const Color inputBorder = Color(0xFFE0E0E0);

  /// Cor da borda dos campos quando focados.
  static const Color inputFocusBorder = Color(0xFF4DB6AC);
}
