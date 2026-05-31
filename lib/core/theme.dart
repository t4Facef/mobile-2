import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xffbb001b),
      surfaceTint: Color(0xffc0001c),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe6182a),
      onPrimaryContainer: Color(0xfffffbff),
      secondary: Color(0xffad3130),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfffe6c66),
      onSecondaryContainer: Color(0xff6d000b),
      tertiary: Color(0xff894d00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffac6200),
      onTertiaryContainer: Color(0xfffffbff),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff291715),
      onSurfaceVariant: Color(0xff5d3f3d),
      outline: Color(0xff926e6b),
      outlineVariant: Color(0xffe7bcb9),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff402b29),
      inversePrimary: Color(0xffffb3ad),
      primaryFixed: Color(0xffffdad7),
      onPrimaryFixed: Color(0xff410004),
      primaryFixedDim: Color(0xffffb3ad),
      onPrimaryFixedVariant: Color(0xff930013),
      secondaryFixed: Color(0xffffdad7),
      onSecondaryFixed: Color(0xff410004),
      secondaryFixedDim: Color(0xffffb3ad),
      onSecondaryFixedVariant: Color(0xff8b181b),
      tertiaryFixed: Color(0xffffdcc0),
      onTertiaryFixed: Color(0xff2d1600),
      tertiaryFixedDim: Color(0xffffb875),
      onTertiaryFixedVariant: Color(0xff6b3b00),
      surfaceDim: Color(0xfff4d2cf),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ef),
      surfaceContainer: Color(0xffffe9e7),
      surfaceContainerHigh: Color(0xffffe2df),
      surfaceContainerHighest: Color(0xfffddbd7),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff73000c),
      surfaceTint: Color(0xffc0001c),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffda0823),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff73010d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc1403d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff532d00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffa25c00),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff1d0d0b),
      onSurfaceVariant: Color(0xff4b2f2d),
      outline: Color(0xff6a4a48),
      outlineVariant: Color(0xff876562),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff402b29),
      inversePrimary: Color(0xffffb3ad),
      primaryFixed: Color(0xffda0823),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xffad0018),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xffc1403d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff9f2727),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xffa25c00),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff7f4700),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffe0bfbc),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ef),
      surfaceContainer: Color(0xffffe2df),
      surfaceContainerHigh: Color(0xfff7d5d2),
      surfaceContainerHighest: Color(0xffebcac7),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff600008),
      surfaceTint: Color(0xffc0001c),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff970013),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff600008),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff8f1a1d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff452400),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff6e3d00),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff402523),
      outlineVariant: Color(0xff60413f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff402b29),
      inversePrimary: Color(0xffffb3ad),
      primaryFixed: Color(0xff970013),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff6d000b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff8f1a1d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff6d000b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff6e3d00),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4e2a00),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd1b1ae),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffffedeb),
      surfaceContainer: Color(0xfffddbd7),
      surfaceContainerHigh: Color(0xffeecdca),
      surfaceContainerHighest: Color(0xffe0bfbc),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffb3ad),
      surfaceTint: Color(0xffffb3ad),
      onPrimary: Color(0xff68000a),
      primaryContainer: Color(0xffff5450),
      onPrimaryContainer: Color(0xff180001),
      secondary: Color(0xffffb3ad),
      onSecondary: Color(0xff68000a),
      secondaryContainer: Color(0xff8f1a1d),
      onSecondaryContainer: Color(0xffff9e97),
      tertiary: Color(0xffffb875),
      onTertiary: Color(0xff4b2800),
      tertiaryContainer: Color(0xffcf7d21),
      onTertiaryContainer: Color(0xff100500),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff200f0d),
      onSurface: Color(0xfffddbd7),
      onSurfaceVariant: Color(0xffe7bcb9),
      outline: Color(0xffae8884),
      outlineVariant: Color(0xff5d3f3d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfffddbd7),
      inversePrimary: Color(0xffc0001c),
      primaryFixed: Color(0xffffdad7),
      onPrimaryFixed: Color(0xff410004),
      primaryFixedDim: Color(0xffffb3ad),
      onPrimaryFixedVariant: Color(0xff930013),
      secondaryFixed: Color(0xffffdad7),
      onSecondaryFixed: Color(0xff410004),
      secondaryFixedDim: Color(0xffffb3ad),
      onSecondaryFixedVariant: Color(0xff8b181b),
      tertiaryFixed: Color(0xffffdcc0),
      onTertiaryFixed: Color(0xff2d1600),
      tertiaryFixedDim: Color(0xffffb875),
      onTertiaryFixedVariant: Color(0xff6b3b00),
      surfaceDim: Color(0xff200f0d),
      surfaceBright: Color(0xff4a3432),
      surfaceContainerLowest: Color(0xff1a0a09),
      surfaceContainerLow: Color(0xff291715),
      surfaceContainer: Color(0xff2d1b19),
      surfaceContainerHigh: Color(0xff392523),
      surfaceContainerHighest: Color(0xff452f2e),
    );
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: GoogleFonts.hankenGroteskTextTheme(
       ThemeData(colorScheme: colorScheme).textTheme,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;


  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
