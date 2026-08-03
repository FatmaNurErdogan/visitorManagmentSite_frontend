import 'package:flutter/material.dart';

/// Vizit's extra design tokens that don't map onto Flutter's [ColorScheme]
/// directly — pulled from the confirmed "Bulut" mockup (soft green light
/// theme, vivid dark theme).
@immutable
class VizitColors extends ThemeExtension<VizitColors> {
  const VizitColors({
    required this.ink,
    required this.soft,
    required this.field,
    required this.divider,
    required this.outlineBg,
    required this.outlineInk,
    required this.chipBg,
    required this.chipInk,
    required this.acceptBg,
    required this.acceptInk,
    required this.warnBg,
    required this.warnInk,
    required this.dangerBg,
    required this.dangerInk,
    required this.cardShadow,
    required this.buttonGlow,
  });

  final Color ink;
  final Color soft;
  final Color field;
  final Color divider;
  final Color outlineBg;
  final Color outlineInk;
  final Color chipBg;
  final Color chipInk;
  final Color acceptBg;
  final Color acceptInk;
  final Color warnBg;
  final Color warnInk;
  final Color dangerBg;
  final Color dangerInk;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonGlow;

  static const light = VizitColors(
    ink: Color(0xFF33453A),
    soft: Color(0xFF82998A),
    field: Color(0xFFE6F5EA),
    divider: Color(0xFFCFEAD4),
    outlineBg: Color(0xFFE6F5EA),
    outlineInk: Color(0xFF4F8A66),
    chipBg: Color(0xFFFFE1C7),
    chipInk: Color(0xFFC97B3D),
    acceptBg: Color(0xFFCDE9FF),
    acceptInk: Color(0xFF3A7EA8),
    warnBg: Color(0xFFFCF0D6),
    warnInk: Color(0xFFB4790F),
    dangerBg: Color(0xFFFAE1DC),
    dangerInk: Color(0xFFB93F30),
    cardShadow: [
      BoxShadow(color: Color(0x1463B686), blurRadius: 4, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x4D63B686), blurRadius: 26, offset: Offset(0, 12)),
    ],
    buttonGlow: [],
  );

  static const dark = VizitColors(
    ink: Color(0xFFEDEBF7),
    soft: Color(0xFF9A94B8),
    field: Color(0xFF29273A),
    divider: Color(0xFF2B2839),
    outlineBg: Color(0xFF29273A),
    outlineInk: Color(0xFFB6ACFF),
    chipBg: Color(0x28FF915C),
    chipInk: Color(0xFFFFB185),
    acceptBg: Color(0x287EE8C0),
    acceptInk: Color(0xFF7EE8C0),
    warnBg: Color(0x33E7B655),
    warnInk: Color(0xFFE7B655),
    dangerBg: Color(0x33E3897C),
    dangerInk: Color(0xFFE3897C),
    cardShadow: [
      BoxShadow(color: Color(0x73000000), blurRadius: 14, offset: Offset(5, 5)),
    ],
    buttonGlow: [
      BoxShadow(color: Color(0x999C8CFF), blurRadius: 22, offset: Offset(0, 10)),
    ],
  );

  @override
  VizitColors copyWith({
    Color? ink,
    Color? soft,
    Color? field,
    Color? divider,
    Color? outlineBg,
    Color? outlineInk,
    Color? chipBg,
    Color? chipInk,
    Color? acceptBg,
    Color? acceptInk,
    Color? warnBg,
    Color? warnInk,
    Color? dangerBg,
    Color? dangerInk,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonGlow,
  }) {
    return VizitColors(
      ink: ink ?? this.ink,
      soft: soft ?? this.soft,
      field: field ?? this.field,
      divider: divider ?? this.divider,
      outlineBg: outlineBg ?? this.outlineBg,
      outlineInk: outlineInk ?? this.outlineInk,
      chipBg: chipBg ?? this.chipBg,
      chipInk: chipInk ?? this.chipInk,
      acceptBg: acceptBg ?? this.acceptBg,
      acceptInk: acceptInk ?? this.acceptInk,
      warnBg: warnBg ?? this.warnBg,
      warnInk: warnInk ?? this.warnInk,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerInk: dangerInk ?? this.dangerInk,
      cardShadow: cardShadow ?? this.cardShadow,
      buttonGlow: buttonGlow ?? this.buttonGlow,
    );
  }

  @override
  VizitColors lerp(ThemeExtension<VizitColors>? other, double t) {
    if (other is! VizitColors) return this;
    return t < 0.5 ? this : other;
  }
}

const _pill = BorderRadius.all(Radius.circular(999));
const _cardRadius = BorderRadius.all(Radius.circular(22));

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colors = VizitColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF63B686),
      brightness: Brightness.light,
      primary: const Color(0xFF63B686),
      onPrimary: Colors.white,
      surface: const Color(0xFFFCFEFC),
      onSurface: colors.ink,
    );
    return _base(scheme, colors, const Color(0xFFFCFEFC));
  }

  static ThemeData dark() {
    const colors = VizitColors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9C8CFF),
      brightness: Brightness.dark,
      primary: const Color(0xFF9C8CFF),
      onPrimary: const Color(0xFF1B1730),
      surface: const Color(0xFF211F2C),
      onSurface: colors.ink,
    );
    return _base(scheme, colors, const Color(0xFF211F2C));
  }

  static ThemeData _base(ColorScheme scheme, VizitColors colors, Color scaffoldBg) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      extensions: [colors],
      textTheme: base.textTheme.apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: _pill, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: _pill, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: _pill,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: colors.soft, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: colors.soft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: _pill),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.outlineBg,
          foregroundColor: colors.outlineInk,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: _pill),
          side: BorderSide.none,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: scaffoldBg,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

/// Shorthand to reach [VizitColors] from a [BuildContext].
extension VizitColorsX on BuildContext {
  VizitColors get vizitColors => Theme.of(this).extension<VizitColors>()!;
}
