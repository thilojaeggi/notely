import 'dart:ui';

import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schulnetz/pages/settings_page.dart';
import 'package:schulnetz/pages/start_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:theme_provider/theme_provider.dart';

import 'pages/absences_page.dart';
import 'pages/grades_page.dart';

class ViewContainerWidget extends StatefulWidget {
  const ViewContainerWidget({Key? key}) : super(key: key);

  @override
  State<ViewContainerWidget> createState() => _ViewContainerWidgetState();
}

class _ViewContainerWidgetState extends State<ViewContainerWidget>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  void changeDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = <Widget>[
    const StartPage(),
    const GradesPage(),
    const AbsencesPage(),
    const SettingsPage(),
  ];

  @override
  initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    getAccessToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getAccessToken();
    }
  }

  Future<void> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    String school = prefs.getString("school") ?? "ksso";
    String username = await storage.read(key: "username") as String;
    String password = await storage.read(key: "password") as String;
    await http.post(
        Uri.parse(
            "https://kaschuso.so.ch/public/$school/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=Yr9Q5dODCujQtTDCZyyYq9MbyECVTNgFha276guJ&redirect_uri=https://www.schul-netz.com/mobile/oauth-callback.html&id="),
        body: {
          "login": username,
          "passwort": password,
        }).then((response) {
      if (response.statusCode == 302) {
        String locationHeader = response.headers['location'].toString();
        var trimmedString =
            locationHeader.substring(0, locationHeader.indexOf('&'));
        trimmedString = trimmedString
            .substring(trimmedString.indexOf("#") + 1)
            .replaceAll("access_token=", "");
        prefs.setString("accessToken", trimmedString);
        print(trimmedString);
      } else {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > 730) {
        return Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: changeDestination,
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(
                      CupertinoIcons.house_fill,
                    ),
                    label: Text('Start'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      CupertinoIcons.text_badge_checkmark,
                    ),
                    label: Text('Noten'),
                  ),
                  NavigationRailDestination(
                      icon: Icon(Icons.sick),
                      label: Text(
                        "Absenzen",
                      )),
                  NavigationRailDestination(
                    icon: Icon(CupertinoIcons.gear_solid),
                    label: Text(
                      "Einstellungen",
                    ),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // This is the main content.
              Expanded(
                child: SafeArea(
                  child: _pages[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      } else {
        return Scaffold(
          extendBody: true,
          bottomNavigationBar: CustomNavigationBar(
            backgroundColor:
                (ThemeProvider.controllerOf(context).currentThemeId ==
                        'dark_theme')
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
            borderRadius: Radius.circular(10.0),
            selectedColor: Colors.blue,
            blurEffect: true,
            iconSize: 30.0,
            scaleFactor: 0.1,
            elevation: 0,
            unSelectedColor: Colors.grey[600],
            items: <CustomNavigationBarItem>[
              CustomNavigationBarItem(
                icon: Icon(
                  CupertinoIcons.house_fill,
                ),
              ),
              CustomNavigationBarItem(
                icon: Icon(
                  CupertinoIcons.text_badge_checkmark,
                ),
              ),
              CustomNavigationBarItem(
                icon: Icon(Icons.sick),
              ),
              CustomNavigationBarItem(
                icon: Icon(CupertinoIcons.gear_solid),
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: changeDestination,
          ),
          body: SafeArea(
            child: _pages[_selectedIndex],
            bottom: false,
            left: true,
            right: true,
            top: true,
          ),
        );
      }
    });
  }
}
