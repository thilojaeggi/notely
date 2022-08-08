import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
        useMaterial3: false,
        fontFamily: "WorkSans",
        primaryColor: isDarkTheme ? Colors.black : Colors.white,
        indicatorColor: isDarkTheme ? Color(0xff0E1D36) : Color(0xffCBDCF8),
        hintColor: isDarkTheme ? Color(0xff280C0B) : Color(0xffEECED3),
        focusColor: isDarkTheme ? Color(0xff0B2512) : Color(0xffA8DAB5),
        disabledColor: Colors.grey,
        cardColor: isDarkTheme ? Color(0xFF151515) : Colors.white,
        canvasColor: isDarkTheme ? Color(0xFF0d0d0d) : Colors.grey[50],
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
            colorScheme:
                isDarkTheme ? ColorScheme.dark() : ColorScheme.light()),
        appBarTheme: AppBarTheme(
          elevation: 0.0,
        ));
  }
}
