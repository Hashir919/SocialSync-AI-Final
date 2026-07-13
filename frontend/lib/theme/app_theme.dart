import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AppTheme {
  static const Color primaryBg = Color(0xFF07080A);
  static const Color panelBg = Color(0xFF0E1014);
  static const Color panelBg2 = Color(0xFF13161B);
  static const Color limeAccent = Color(0xFFD8FF3E);
  static const Color primaryBlue = Color(0xFF70A7FF);
  static const Color accentPurple = Color(0xFF9C83FF);
  static const Color lineBorder = Color(0x14FFFFFF);
  static const Color textMuted = Color(0xFF777C86);
  static const Color successGreen = Color(0xFF4CD964);
  static const Color warningOrange = Color(0xFFFF9500);

  static ThemeData getLightTheme() {
    // Standardizing on dark OLED aesthetic for exhibitions, light theme is identical to keep dark premium direction
    return getDarkTheme();
  }

  static ThemeData getDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: primaryBg,
      colorScheme: const ColorScheme.dark(
        primary: limeAccent,
        secondary: primaryBlue,
        tertiary: accentPurple,
        background: primaryBg,
        surface: panelBg,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.manrope(
          fontSize: 34, 
          fontWeight: FontWeight.w800, 
          color: Colors.white,
          letterSpacing: -1.8,
          height: 1.05,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28, 
          fontWeight: FontWeight.w700, 
          color: Colors.white,
          letterSpacing: -1.2,
          height: 1.12,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 16, 
          fontWeight: FontWeight.w600, 
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 14, 
          color: Color(0xFFF4F5F7),
          height: 1.55,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 13, 
          color: textMuted,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.dmMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
          letterSpacing: 1.8,
        ),
      ),
      useMaterial3: true,
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.055,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Colors.white;
    final defaultBorder = border ?? Border.all(
      color: AppTheme.lineBorder,
      width: 1.0,
    );
    final defaultRadius = borderRadius ?? BorderRadius.circular(22);

    return ClipRRect(
      borderRadius: defaultRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: defaultColor.withOpacity(opacity),
            borderRadius: defaultRadius,
            border: defaultBorder,
          ),
          child: child,
        ),
      ),
    );
  }
}
