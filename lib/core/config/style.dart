import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      useMaterial3: false,
      fontFamily: "Poppins",
      primaryColor: Colors.blueAccent,
      hintColor:
          isDarkTheme ? const Color(0xff280C0B) : const Color(0xffEECED3),
      focusColor:
          isDarkTheme ? const Color(0xff0B2512) : const Color(0xffA8DAB5),
      disabledColor: Colors.grey,
      cardColor: isDarkTheme ? const Color(0xFF151515) : Colors.white,
      canvasColor: isDarkTheme ? const Color(0xFF0d0d0d) : Colors.grey[50],
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      bottomSheetTheme: const BottomSheetThemeData(
        // Applies a global maximum width (common for tablets/desktop)
        constraints: BoxConstraints(maxWidth: 700),
      ),
      buttonTheme: Theme.of(context).buttonTheme.copyWith(
          colorScheme: isDarkTheme
              ? const ColorScheme.dark()
              : const ColorScheme.light()),
      appBarTheme: const AppBarTheme(
        elevation: 0.0,
      ),
      switchTheme:
          SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.blue;
        } else {
          return Colors.grey;
        }
      }), trackColor: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.selected)) {
          return Colors.grey.withValues(alpha: .48);
        }
        return Colors.blue.withValues(alpha: 0.48);
      })),
      tabBarTheme: TabBarThemeData(
          indicatorColor:
              isDarkTheme ? const Color(0xff0E1D36) : const Color(0xffCBDCF8)),
    );
  }
}
