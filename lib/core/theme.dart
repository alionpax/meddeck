import 'package:flutter/material.dart';

// Playful Aurora theme (vibrant, colorful, motion-friendly)
// Purple, Magenta, Sun Yellow
ThemeData buildPlayfulTheme({bool dark = false}) {
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

// Tropical Sunset theme (warm, vibrant, energetic)
// Orange, Pink, Turquoise
ThemeData buildTropicalTheme({bool dark = false}) {
  const primary = Color(0xFFFF6B35); // vibrant orange
  const secondary = Color(0xFFFF1493); // deep pink
  const accent = Color(0xFF00CED1); // turquoise
  const bgLight = Color(0xFFFFF8F0);
  const bgDark = Color(0xFF1A0F0A);

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
    surface: dark ? const Color(0xFF2A1510) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black,
    tertiary: accent,
    onTertiary: Colors.black,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF3A2520) : const Color(0xFFFFE8D6),
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

// Candy Pop theme (sweet, playful, bubbly)
// Bubble Gum Pink, Electric Blue, Lime Green
ThemeData buildCandyTheme({bool dark = false}) {
  const primary = Color(0xFFFF69B4); // hot pink
  const secondary = Color(0xFF00BFFF); // deep sky blue
  const accent = Color(0xFF32CD32); // lime green
  const bgLight = Color(0xFFFFF0F8);
  const bgDark = Color(0xFF1A0814);

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
    surface: dark ? const Color(0xFF2A1020) : Colors.white,
    onSurface: dark ? Colors.white : Colors.black,
    tertiary: accent,
    onTertiary: Colors.black,
    outline: dark ? Colors.white24 : Colors.black26,
    shadow: Colors.black,
    surfaceVariant: dark ? const Color(0xFF3A1830) : const Color(0xFFFFE0F0),
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

// Forest Green theme (nature-inspired, calming, green-focused)
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
