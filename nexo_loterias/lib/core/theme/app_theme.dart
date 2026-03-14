import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme({
    required Color primary,
    required Color secondary,
    required Color destaque,
    bool dark = true,
  }) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final bgColor = dark ? AppColors.background : const Color(0xFFF5F5F5);
    final surfaceColor = dark ? AppColors.surface : Colors.white;
    final onBgColor = dark ? AppColors.onBackground : const Color(0xFF1A1A1A);
    final onSurfaceColor = dark ? AppColors.onSurface : const Color(0xFF333333);
    final textSecColor = dark ? AppColors.textSecondary : const Color(0xFF757575);
    final dividerColor = dark ? AppColors.divider : const Color(0xFFE0E0E0);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: primary,
              secondary: secondary,
              tertiary: destaque,
              surface: surfaceColor,
              onPrimary: Colors.white,
              onSecondary: primary,
              onSurface: onSurfaceColor,
            )
          : ColorScheme.light(
              primary: primary,
              secondary: secondary,
              tertiary: destaque,
              surface: surfaceColor,
              onPrimary: Colors.white,
              onSecondary: primary,
              onSurface: onSurfaceColor,
            ),
      fontFamily: 'Poppins',
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: onBgColor,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onBgColor),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: onBgColor),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onBgColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onBgColor),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: onBgColor),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: onSurfaceColor),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onBgColor),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: textSecColor),
      ),
    );
  }

  static ThemeData get megaSena => buildTheme(
        primary: AppColors.megaSenaPrimary,
        secondary: AppColors.megaSenaSecondary,
        destaque: AppColors.megaSenaDestaque,
      );

  static ThemeData get lotofacil => buildTheme(
        primary: AppColors.lotofacilPrimary,
        secondary: AppColors.lotofacilSecondary,
        destaque: AppColors.lotofacilDestaque,
      );

  static ThemeData megaSenaClaro() => buildTheme(
        primary: AppColors.megaSenaPrimary,
        secondary: AppColors.megaSenaSecondary,
        destaque: AppColors.megaSenaDestaque,
        dark: false,
      );

  static ThemeData lotofacilClaro() => buildTheme(
        primary: AppColors.lotofacilPrimary,
        secondary: AppColors.lotofacilSecondary,
        destaque: AppColors.lotofacilDestaque,
        dark: false,
      );
}
