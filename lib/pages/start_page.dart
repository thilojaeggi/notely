import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../ad_helper.dart';
import '../config/Globals.dart' as Globals;

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  String _name = "";
  String _email = "";
  List _classList = List.empty(growable: true);
  final storage = const FlutterSecureStorage();
  String school = "";
  Map<String, dynamic> _user = Map();

  late BannerAd _bottomBannerAd;
  bool _isBottomBannerAdLoaded = false;

  void _createBottomBannerAd() {
    _bottomBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBottomBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bottomBannerAd.load();
  }

  Future<void> getExistingValues() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _classList =
            jsonDecode(prefs.getString('classes') ?? jsonEncode(List.empty()));
        _name = prefs.getString('name') ?? "";
        _email = prefs.getString('email') ?? "";
      });
    }
  }

  Future<void> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    school = await prefs.getString("school") ?? "ksso";
    print(Globals.accessToken);
    print(school);
    String url = Globals.apiBase + "/me";
    print(url);

    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        _user = jsonDecode(response.body);
      });
    } catch (e) {
      print(e.toString());
    }
    _classList.clear();
    if (mounted) {
      setState(() {
        _name = _user['firstName'] + " " + _user['lastName'];
        _email = _user['email'];
        for (var schoolClass in _user['regularClasses']) {
          _classList.add(schoolClass['token']);
        }
      });
    }
    print(_user['firstName'] + " " + _user['lastName']);
    await prefs.setString('name', _user['firstName'] + " " + _user['lastName']);
    await prefs.setString('email', _user['email']);
    await prefs.setString('classes', jsonEncode(_classList));
  }

  @override
  initState() {
    super.initState();
    getExistingValues();
    getMe();
    if (!Platform.isWindows) {
      // _createBottomBannerAd();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (!Platform.isWindows) {
      //_bottomBannerAd.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ich",
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Text(
                    "Klassen:",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
                  ),
                  for (var i = 0; i < _classList.length; i++)
                    Text(
                      _classList[i].toString(),
                      style: const TextStyle(fontSize: 20),
                    )
                ],
              ),
            ),
            const Spacer(),
            (_isBottomBannerAdLoaded && !Platform.isWindows)
                ? Container(
                    height: _bottomBannerAd.size.height.toDouble(),
                    width: double.infinity,
                    child: AdWidget(ad: _bottomBannerAd),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
