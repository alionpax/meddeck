import 'package:flutter/material.dart';


// Forest Green theme: nature-inspired, calming, green-focused
ThemeData buildForestTheme({bool dark = false}) {
  const primary = Color(0xFF2E7D32); // forest green
  const secondary = Color(0xFF81C784); // light green
  const accent = Color(0xFFFFD600); // yellow accent
  const bgLight = Color(0xFFF1F8E9);
  const bgDark = Color(0xFF1B2B1B);

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: Colors.red.shade400,
    onError: Colors.white,
    background: dark ? bgDark : bgLight,
    onBackground: dark ? Colors.white : Colors.black,
    surface: dark ? const Color(0xFF263A29) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black,
    tertiary: accent,
    onTertiary: Colors.black,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF2E3D2F) : const Color(0xFFE8F5E9),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: dark ? Brightness.dark : Brightness.light,
  );

  final textTheme = base.textTheme.copyWith(
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.onBackground,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground.withOpacity(0.85),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.background,
    cardColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      surfaceTintColor: colorScheme.surface,
      iconTheme: IconThemeData(color: colorScheme.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onBackground.withOpacity(0.68),
      backgroundColor: colorScheme.surface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}

// Monochrome theme: grayscale, minimal, high-contrast
ThemeData buildMonochromeTheme({bool dark = false}) {
  const primary = Color(0xFF222222);
  const secondary = Color(0xFF888888);
  const accent = Color(0xFFCCCCCC);
  const bgLight = Color(0xFFF8F8F8);
  const bgDark = Color(0xFF181818);

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: Colors.red.shade400,
    onError: Colors.white,
    background: dark ? bgDark : bgLight,
    onBackground: dark ? Colors.white : Colors.black,
    surface: dark ? const Color(0xFF232323) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black,
    tertiary: accent,
    onTertiary: Colors.black,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF232323) : const Color(0xFFE0E0E0),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: dark ? Brightness.dark : Brightness.light,
  );

  final textTheme = base.textTheme.copyWith(
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.onBackground,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground.withOpacity(0.85),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.background,
    cardColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      surfaceTintColor: colorScheme.surface,
      iconTheme: IconThemeData(color: colorScheme.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onBackground.withOpacity(0.68),
      backgroundColor: colorScheme.surface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}

// MedDeck theme: coral-to-purple gradient inspired by the app icon
ThemeData buildMedDeckTheme({bool dark = false}) {
  const primary = Color(0xFFE85B9A); // coral-pink from icon
  const secondary = Color(0xFF7B3FF2); // purple from icon
  const accent = Color(0xFFFF6B4C); // coral accent
  const bgLight = Color(0xFFFDF7FA);
  const bgDark = Color(0xFF1A1423);

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: Colors.red.shade400,
    onError: Colors.white,
    background: dark ? bgDark : bgLight,
    onBackground: dark ? Colors.white : Colors.black87,
    surface: dark ? const Color(0xFF2A1F35) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black87,
    tertiary: accent,
    onTertiary: Colors.white,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF3A2E45) : const Color(0xFFF3E5F5),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: dark ? Brightness.dark : Brightness.light,
  );

  final textTheme = base.textTheme.copyWith(
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.onBackground,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground.withOpacity(0.85),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.background,
    cardColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      surfaceTintColor: colorScheme.surface,
      iconTheme: IconThemeData(color: colorScheme.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onBackground.withOpacity(0.68),
      backgroundColor: colorScheme.surface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}

TextTheme _safeApply(TextTheme Function() fn, TextTheme fallback) {
  try {
    return fn();
  } catch (_) {
    return fallback;
  }
}

// Legacy theme kept for reference. Prefer `buildPlayfulTheme()` for the new UI.
ThemeData buildClinicalTheme() {
  const bg = Color(0xFFFAFAFA);
  const surface = Colors.white;
  const textPrimary = Color(0xFF111111);
  const textSecondary = Color(0xFF6B7280);
  const divider = Color(0xFFE5E7EB);
  const accent = Color(0xFF2563EB);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: accent),
  );

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    cardColor: surface,
    dividerColor: divider,
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
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

// Playful Aurora theme (vibrant, colorful, motion-friendly)
ThemeData buildPlayfulTheme({bool dark = false}) {
  // Palette: Deep Purple, Magenta, Sun Yellow, Soft Sky
  const primary = Color(0xFF6A00F4);
  const secondary = Color(0xFFFF4D8D);
  const accent = Color(0xFFFFC94D);
  const softSky = Color(0xFFE6F7FF);
  const bgLight = Color(0xFFF7FBFF);
  const bgDark = Color(0xFF0B1020);

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: Colors.red.shade400,
    onError: Colors.white,
    background: dark ? bgDark : bgLight,
    onBackground: dark ? Colors.white : Colors.black,
    surface: dark ? const Color(0xFF071018) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black,
    tertiary: accent,
    onTertiary: Colors.black,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF0F1724) : softSky,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: dark ? Brightness.dark : Brightness.light,
  );

  final textTheme = base.textTheme.copyWith(
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.onBackground,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground.withOpacity(0.9),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.background,
    cardColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: colorScheme.background,
      iconTheme: IconThemeData(color: colorScheme.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onBackground.withOpacity(0.7),
      backgroundColor: colorScheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: Colors.white,
    ),
  );
}

// "Medical Atlas" theme: educational, refined, medical-professional
ThemeData buildMedicalTheme({bool dark = false}) {
  const primary = Color(0xFF0B3D91); // deep navy
  const secondary = Color(0xFF138D75); // teal
  const accent = Color(0xFFFFB020); // warm amber accent for highlights
  const paper = Color(0xFFF6F7FB);
  const deepSurface = Color(0xFF0B1020);

  final colorScheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: Colors.red.shade400,
    onError: Colors.white,
    background: dark ? deepSurface : paper,
    onBackground: dark ? Colors.white : Colors.black87,
    surface: dark ? const Color(0xFF071025) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black87,
    tertiary: accent,
    onTertiary: Colors.black,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF0F1724) : const Color(0xFFF1F5F9),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: dark ? Brightness.dark : Brightness.light,
  );

  final textTheme = base.textTheme.copyWith(
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.onBackground,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: colorScheme.onBackground.withOpacity(0.85),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.background,
    cardColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      surfaceTintColor: colorScheme.surface,
      iconTheme: IconThemeData(color: colorScheme.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onBackground.withOpacity(0.68),
      backgroundColor: colorScheme.surface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}
