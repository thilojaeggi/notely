import 'dart:ui';

import 'package:notely/pages/timetable_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    FirebaseAnalytics.instance.logScreenView(screenName: _pageNames[index]);
  }

  final List<Widget> _pages = <Widget>[
    const StartPage(),
    const TimetablePage(),
    const GradesPage(),
    const AbsencesPage(),
    const SettingsPage(),
  ];

  final List<String> _pageNames = [
    'StartPage',
    'TimetablePage',
    'GradesPage',
    'AbsencesPage',
    'SettingsPage',
  ];

  @override
  initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    FirebaseAnalytics.instance
        .logScreenView(screenName: _pageNames[_selectedIndex]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {}
  }

  void bottomTapped(int index) {
    setState(() {
      pageController.animateToPage(index,
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > 730) {
        return Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 730),
              child: Scaffold(
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
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Theme.of(context).canvasColor,
              ),
            ),
          ],
        );
      } else {
        return Scaffold(
          extendBody: true,
          body: SafeArea(
            bottom: false,
            left: true,
            right: true,
            top: false,
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
          ),
          bottomNavigationBar: newMethod(),
        );
      }
    });
  }

  Container newMethod() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          backgroundColor: Colors.grey.withValues(alpha: 0.1),
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
                icon: Icon(CupertinoIcons.gear_solid), label: "Einstellungen"),
          ],
          currentIndex: _selectedIndex,
          onTap: bottomTapped,
        ),
      ),
    );
  }
}
