import 'dart:ui';

import 'package:flutter/material.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.blue[400],
        fontFamily: "WorkSans",
        primaryColor: isDarkTheme ? Colors.black : Colors.white,
        backgroundColor: isDarkTheme ? Colors.black : Color(0xffF1F5FB),
        indicatorColor: isDarkTheme ? Color(0xff0E1D36) : Color(0xffCBDCF8),
        hintColor: isDarkTheme ? Color(0xff280C0B) : Color(0xffEECED3),
        focusColor: isDarkTheme ? Color(0xff0B2512) : Color(0xffA8DAB5),
        disabledColor: Colors.grey,
        cardColor: isDarkTheme ? Color(0xFF151515) : Colors.white,
        canvasColor: isDarkTheme ? Colors.black : Colors.grey[50],
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
            colorScheme:
                isDarkTheme ? ColorScheme.dark() : ColorScheme.light()),
        appBarTheme: AppBarTheme(
          elevation: 0.0,
        ),
        bottomNavigationBarTheme:
            Theme.of(context).bottomNavigationBarTheme.copyWith(
                  backgroundColor: isDarkTheme
                      ? Color.fromARGB(255, 27, 27, 27).withOpacity(0.2)
                      : Colors.white,
                ));
  }
}
