import 'package:flutter/material.dart';

/// Paleta de cores do aplicativo
/// Substituindo FranceColors por cores com identidade financeira
class AppColors {
  // Cor principal — azul escuro, transmite confiança e estabilidade
  static const Color primary = Color(0xFF1A237E);

  // Cor secundária — coral/vermelho suave, usado para despesas
  static const Color secondary = Color(0xFFE53935);

  // Verde, usado para receitas e saldo positivo
  static const Color income = Color(0xFF2E7D32);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
}

// Light Theme
final ThemeData appLightTheme = _buildTheme(Brightness.light);

// Dark Theme
final ThemeData appDarkTheme = _buildTheme(Brightness.dark);

//mudança de paleta
ThemeData _buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;

  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.income,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        isDark ? colorScheme.surface : AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(color: colorScheme.onSurface),
      bodyLarge: TextStyle(color: colorScheme.onSurface),
      bodyMedium: TextStyle(color: colorScheme.onSurface),
      labelLarge: TextStyle(color: AppColors.white),
    ),
  );
}