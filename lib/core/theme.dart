import 'package:flutter/material.dart';

ThemeData buildClinicalTheme() {
  const bg = Color(0xFFFAFAFA);
  const surface = Colors.white;
  const textPrimary = Color(0xFF111111);
  const textSecondary = Color(0xFF6B7280);
  const divider = Color(0xFFE5E7EB);
  const accent = Color(0xFF2563EB);

  final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: accent));

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    cardColor: surface,
    dividerColor: divider,
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      bodyMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: bg,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: accent,
      unselectedItemColor: textSecondary,
      backgroundColor: surface,
    ),
  );
}
