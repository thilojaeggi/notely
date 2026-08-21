import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notely/core/analytics/analytics_constants.dart';
import 'package:notely/core/analytics/analytics_service.dart';
import 'package:notely/features/subscription/subscription_manager.dart';
import 'package:notely/features/widget/widget_sync_service.dart';
import 'package:notely/pages/timetable_page.dart';

import '../pages/absences_page.dart';
import '../pages/grades_page.dart';
import '../pages/settings_page.dart';
import '../pages/start_page.dart';

class ViewContainerWidget extends StatefulWidget {
  final int initialIndex;
  final String? initialDeepLink;

  const ViewContainerWidget({
    Key? key,
    this.initialIndex = 0,
    this.initialDeepLink,
  }) : super(key: key);

  @override
  State<ViewContainerWidget> createState() => _ViewContainerWidgetState();
}

class _ViewContainerWidgetState extends State<ViewContainerWidget>
    with WidgetsBindingObserver {
  late PageController pageController;
  late int _selectedIndex;

  static const _deeplinkChannel = MethodChannel('ch.notely.app/deeplink');
  bool _isPresentingPaywall = false;
  bool _isNavigatingProgrammatically = false;

  void changeDestination(int index) {
    if (_isNavigatingProgrammatically) return;
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    AnalyticsService().logScreenView(screenName: _pageNames[index]);
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
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialIndex;
    pageController = PageController(
      initialPage: widget.initialIndex,
      keepPage: true,
    );
    super.initState();
    AnalyticsService().logScreenView(screenName: _pageNames[_selectedIndex]);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Listen for deep links while app is running (warm start)
    _deeplinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        _handleDeepLink(call.arguments as String?);
      }
    });

    if (widget.initialDeepLink != null) {
      _handleDeepLink(widget.initialDeepLink);
      return;
    }

    // Check for a pending deep link from cold start if not already resolved
    try {
      final pending =
          await _deeplinkChannel.invokeMethod<String?>('getPendingDeepLink');
      _handleDeepLink(pending);
    } catch (e) {
      debugPrint('Failed to get pending deep link: $e');
    }
  }

  String? _lastHandledUrl;
  DateTime? _lastHandledTime;

  void _handleDeepLink(String? url) {
    if (url == null) return;
    final now = DateTime.now();
    if (_lastHandledUrl == url &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!).inMilliseconds < 1500) {
      debugPrint('Ignoring duplicate deep link within 1.5s: $url');
      return;
    }
    _lastHandledUrl = url;
    _lastHandledTime = now;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final target = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
    AnalyticsService().logDeepLinkOpened(target: target, rawUrl: url);

    if (target == 'paywall') {
      if (!SubscriptionManager().isPremium && !_isPresentingPaywall) {
        _isPresentingPaywall = true;
        // Delay to ensure route transition is fully complete
        Future.delayed(const Duration(milliseconds: 600), () async {
          if (!mounted) {
            _isPresentingPaywall = false;
            return;
          }
          await SubscriptionManager().presentNotelyPremiumPaywall(
            source: PaywallSource.deepLink,
          );
          _isPresentingPaywall = false;
        });
      }
    } else if (target == 'timetable' || target == 'plan') {
      if (_selectedIndex != 1) bottomTapped(1);
    } else if (target == 'grades' || target == 'noten') {
      if (_selectedIndex != 2) bottomTapped(2);
    } else if (target == 'absences' || target == 'absenzen') {
      if (_selectedIndex != 3) bottomTapped(3);
    } else if (target == 'settings' || target == 'einstellungen') {
      if (_selectedIndex != 4) bottomTapped(4);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    _handleDeepLink(uri.toString());
    return true;
  }

  @override
  Future<bool> didPushRoute(String route) async {
    _handleDeepLink(route);
    return true;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // Sync the next 7 days of schedule data to the widget
      WidgetSyncService().syncScheduleToWidget();
    }
  }

  void bottomTapped(int index) {
    if (_selectedIndex == index) return;
    _isNavigatingProgrammatically = true;
    setState(() {
      _selectedIndex = index;
    });
    AnalyticsService().logScreenView(screenName: _pageNames[index]);
    if (pageController.hasClients) {
      pageController
          .animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      )
          .then((_) {
        _isNavigatingProgrammatically = false;
      });
    } else {
      _isNavigatingProgrammatically = false;
    }
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
                          icon: Icon(
                            CupertinoIcons.person_crop_circle_badge_xmark,
                          ),
                          label: Text(
                            "Absenzen",
                          ),
                        ),
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
                if (!_isNavigatingProgrammatically) {
                  changeDestination(index);
                } else if (index == _selectedIndex) {
                  _isNavigatingProgrammatically = false;
                }
              },
              itemBuilder: (BuildContext context, int index) {
                return _pages[index];
              },
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      }
    });
  }

  Widget _buildBottomNavigationBar() {
    return CNTabBar(
      currentIndex: _selectedIndex,
      onTap: bottomTapped,
      items: const [
        CNTabBarItem(
          label: "Start",
          icon: CNSymbol("house.fill"),
        ),
        CNTabBarItem(
          label: "Plan",
          icon: CNSymbol("calendar"),
        ),
        CNTabBarItem(
          label: "Noten",
          icon: CNSymbol("text.badge.checkmark"),
        ),
        CNTabBarItem(
          label: "Absenzen",
          icon: CNSymbol("person.crop.circle.badge.xmark"),
        ),
        CNTabBarItem(
          label: "Einstellungen",
          icon: CNSymbol("gearshape.fill"),
        ),
      ],
    );
  }
}
