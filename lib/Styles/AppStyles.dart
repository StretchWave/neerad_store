import 'package:flutter/material.dart';

class AppStyles {
  // Colors - Light
  static const Color primaryTeal = Color(0xFF75B1B8);
  static const Color sidebarBg = Color(0xFFD9D9D9);
  static const Color inputBg = Color(0xFFD9D9D9);
  static const Color tableHeaderBg = Color(0xFFD9D9D9);
  static const Color textDark = Color(0xFF000000);

  // Colors - Dark
  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkSidebarBg = Color(0xFF2D2D2D);
  static const Color darkInputBg = Color(0xFF3D3D3D);
  static const Color darkTableHeaderBg = Color(0xFF333333);
  static const Color textLight = Color(0xFFFFFFFF);

  static Color getSidebarBg(bool isDark) => isDark ? darkSidebarBg : sidebarBg;
  static Color getInputBg(bool isDark) => isDark ? darkInputBg : inputBg;
  static Color getTableHeaderBg(bool isDark) =>
      isDark ? darkTableHeaderBg : tableHeaderBg;
  static Color getTextColor(bool isDark) => isDark ? textLight : textDark;
  static Color getScaffoldBg(bool isDark) => isDark ? darkBg : Colors.white;

  // Static Text Styles (using default colors, will be overridden in widgets if needed)
  static const TextStyle screenTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonText = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle dpPriceStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1D5A61),
  );

  // Dynamic style getters
  static TextStyle getScreenTitleStyle(bool isDark) =>
      screenTitle.copyWith(color: getTextColor(isDark));

  static TextStyle getLabelStyle(bool isDark) =>
      labelStyle.copyWith(color: getTextColor(isDark));

  static TextStyle getTableHeaderStyle(bool isDark) =>
      tableHeader.copyWith(color: getTextColor(isDark));

  // Dialog Styles
  static Color getDialogBgColor(bool isDark) =>
      isDark ? const Color(0xFF2D2D2D) : Colors.white;

  static TextStyle getDialogTitleStyle(bool isDark) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: getTextColor(isDark),
  );

  static TextStyle getDialogHeaderStyle(bool isDark) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: getTextColor(isDark),
  );

  static TextStyle getDialogTextStyle(bool isDark) =>
      TextStyle(fontSize: 14, color: getTextColor(isDark));

  static Color getDividerColor(bool isDark) =>
      isDark ? Colors.white12 : Colors.black12;
}
