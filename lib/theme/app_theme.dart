import 'package:flutter/material.dart';

/// Bộ màu thương hiệu dùng chung cho toàn bộ giao diện.
abstract final class AppColors {
  static const emerald = Color(0xFF0F766E);
  static const emeraldDeep = Color(0xFF0B3D38);
  static const emeraldLight = Color(0xFF34D399);
  static const mint = Color(0xFF0EA5A2);

  static const coral = Color(0xFFF97362);
  static const amber = Color(0xFFF59E0B);
  static const violet = Color(0xFF8B5CF6);
  static const sky = Color(0xFF38BDF8);

  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const canvas = Color(0xFFF4F7F8);

  static const darkBg = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF131C2E);
  static const darkLine = Color(0xFF243049);

  static const heroGradient = LinearGradient(
    colors: [emeraldDeep, emerald, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF38BDF8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Font hệ thống ưu tiên Inter → Roboto/Segoe UI. Sử dụng font hệ thống giúp
/// ứng dụng không cần tải font từ internet khi chạy offline.
const String _fontFamily = 'Inter';
const List<String> _fontFallback = ['Roboto', 'Segoe UI', 'Arial', 'sans-serif'];

const List<String> fontFallback = _fontFallback;

TextTheme appTextTheme(ColorScheme scheme, {required bool dark}) {
  final base = Typography.material2021(colorScheme: scheme).black.apply(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFallback,
    bodyColor: dark ? const Color(0xFFE2E8F0) : AppColors.ink,
    displayColor: dark ? Colors.white : AppColors.ink,
  );
  return base;
}

/// Bảng màu theo sắc thái giảng viên (avatar/ranking badge).
const List<Color> teacherPalette = [
  Color(0xFF0F766E),
  Color(0xFF8B5CF6),
  Color(0xFFF97362),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFF6366F1),
];

Color colorForId(String id) {
  if (id.isEmpty) return teacherPalette.first;
  final hash = id.codeUnits.fold<int>(0, (acc, unit) => acc + unit * 7);
  return teacherPalette[hash % teacherPalette.length];
}

abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.emerald, dark: false);

  static ThemeData dark() => _build(AppColors.emeraldLight, dark: true);

  static ThemeData _build(Color seed, {required bool dark}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: dark ? Brightness.dark : Brightness.light)
        .copyWith(
          primary: seed,
          secondary: dark ? AppColors.sky : AppColors.mint,
          surface: dark ? AppColors.darkSurface : Colors.white,
          error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFDC2626),
        );
    final text = appTextTheme(scheme, dark: dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      scaffoldBackgroundColor: dark ? AppColors.darkBg : AppColors.canvas,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? AppColors.darkSurface : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: dark ? AppColors.darkLine : AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF182338) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: dark ? const Color(0xFF7C8AA5) : AppColors.inkSoft),
        labelStyle: TextStyle(color: dark ? const Color(0xFF9FB0C7) : AppColors.inkSoft),
        prefixIconColor: dark ? const Color(0xFF9FB0C7) : AppColors.inkSoft,
        suffixIconColor: dark ? const Color(0xFF9FB0C7) : AppColors.inkSoft,
        border: _border(dark ? AppColors.darkLine : AppColors.line),
        enabledBorder: _border(dark ? AppColors.darkLine : AppColors.line),
        focusedBorder: _border(scheme.primary, width: 1.6),
        errorBorder: _border(scheme.error),
        focusedErrorBorder: _border(scheme.error, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: dark ? AppColors.darkLine : AppColors.line),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1E293B) : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? AppColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E293B) : AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? AppColors.darkLine : AppColors.line,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: dark ? AppColors.darkLine : AppColors.line),
        labelStyle: text.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Tiện ích lấy màu bề mặt/nền theo theme hiện tại.
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => isDark ? AppColors.darkSurface : Colors.white;
  Color get lineColor => isDark ? AppColors.darkLine : AppColors.line;
  Color get mutedColor => isDark ? const Color(0xFF9FB0C7) : AppColors.inkSoft;
  Color get softFill => isDark ? const Color(0x1AFFFFFF) : const Color(0xFFF1F5F4);

  /// Bóng đổ mềm cho card.
  List<BoxShadow> get softShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];
}
