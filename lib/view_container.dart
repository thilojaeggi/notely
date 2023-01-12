import 'dart:ui';

import 'package:notely/pages/timetable_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'Globals.dart' as Globals;

import 'Globals.dart';
import 'pages/absences_page.dart';
import 'pages/grades_page.dart';
import 'pages/settings_page.dart';
import 'pages/start_page.dart';

class ViewContainerWidget extends StatefulWidget {
  const ViewContainerWidget({Key? key}) : super(key: key);

  @override
  State<ViewContainerWidget> createState() => _ViewContainerWidgetState();
}

class _ViewContainerWidgetState extends State<ViewContainerWidget>
    with WidgetsBindingObserver {
  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );
  int _selectedIndex = 0;

  void changeDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = <Widget>[
    const StartPage(),
    const TimetablePage(),
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

  void bottomTapped(int index) {
    setState(() {
      pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.ease);
    });
  }

  Future<void> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    String school = prefs.getString("school") ?? "ksso";
    String username = await storage.read(key: "username") as String;
    String password = await storage.read(key: "password") as String;
    await http.post(
        Uri.parse(Globals.apiBase +
            school.toLowerCase() +
            "/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=Yr9Q5dODCujQtTDCZyyYq9MbyECVTNgFha276guJ&redirect_uri=https://www.schul-netz.com/mobile/oauth-callback.html&id="),
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
        Globals.accessToken = trimmedString;
      }
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
                      CupertinoIcons.calendar_today,
                    ),
                    label: Text('Plan'),
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
          body: SafeArea(
            child: PageView.builder(
              controller: pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                changeDestination(index);
                _selectedIndex = index;
              },
              itemBuilder: (BuildContext context, int index) {
                return _pages[index];
              },
            ),
            bottom: false,
            left: true,
            right: true,
            top: true,
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              useMaterial3: true,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: BackdropFilter(
                filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.blue[400],
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  elevation: 0,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                        icon: Icon(
                          CupertinoIcons.house_fill,
                        ),
                        label: "Start"),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.calendar_today),
                      label: "Plan",
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(
                          CupertinoIcons.text_badge_checkmark,
                        ),
                        label: "Noten"),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.sick),
                      label: "Absenzen",
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(CupertinoIcons.gear_solid),
                        label: "Einstellungen"),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: bottomTapped,
                ),
              ),
            ),
          ),
        );
      }
    });
  }
}
