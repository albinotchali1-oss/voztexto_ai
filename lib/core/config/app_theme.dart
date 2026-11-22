import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

/// Tema Material 3 compartilhado pela aplicação.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.teal,
          surface: AppColors.white,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: AppColors.ink,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          titleMedium: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: AppColors.muted, height: 1.45),
        ),
      );
}