import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFFAC3333);
  static const _secondary = Color(0xFF373839);

  static ThemeData get light => ThemeData(
    // colorScheme: ColorScheme.fromSeed(seedColor: _primary),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _secondary,
      elevation: 1,
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffAC3333)),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ).copyWith(
      bodyMedium : GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      labelLarge : GoogleFonts.poppins(fontWeight: FontWeight.w700),
    ),

  );

  static const primary = _primary;
  static const secondary = _secondary;
}
