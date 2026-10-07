import 'package:flutter/material.dart';

class AppColors {
  static const Color verdeEscuro = Color(0xFF0B3D2E);
  static const Color verdeMedio = Color(0xFF145A43);
  static const Color verdeClaro = Color(0xFFE8F2ED);
  static const Color dourado = Color(0xFFD4AF37);
  static const Color douradoClaro = Color(0xFFF6E8A8);
  static const Color branco = Color(0xFFFFFFFF);
  static const Color fundo = Color(0xFFF7F9F8);
  static const Color texto = Color(0xFF18312A);
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.verdeEscuro,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.verdeEscuro,
      secondary: AppColors.dourado,
      surface: AppColors.branco,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.verdeEscuro,
        foregroundColor: AppColors.branco,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.branco,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: AppColors.branco,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.branco,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: Color(0xFFE1E8E5),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.branco,
        labelStyle: const TextStyle(
          color: AppColors.verdeMedio,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.verdeEscuro,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.verdeMedio,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD8E2DE),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD8E2DE),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.dourado,
            width: 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verdeEscuro,
          foregroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verdeEscuro,
          side: const BorderSide(
            color: AppColors.verdeEscuro,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.verdeEscuro,
        contentTextStyle: const TextStyle(
          color: AppColors.branco,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4EAE7),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.verdeEscuro,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.texto,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.texto,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.texto,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.texto,
        ),
        bodyMedium: TextStyle(
          color: AppColors.texto,
        ),
      ),
    );
  }
}
