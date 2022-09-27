import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  Future<void> getExistingValues() async {
    final prefs = await SharedPreferences.getInstance();
    _classList =
        jsonDecode(prefs.getString('classes') ?? jsonEncode(List.empty()));
    if (mounted) {
      setState(() {
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
    String url = Globals.apiBase + school.toLowerCase() + "/rest/v1" + "/me";
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
        if (Globals.debug) {
          _name = "Max Mustermann";
          _email = "u50365@ksso.ch";
        } else {
          _name = _user['firstName'];
          _email = _user['email'];
        }
        _name = _name.split(' ').first;

        for (var schoolClass in _user['regularClasses']) {
          _classList.add(schoolClass['token']);
        }
      });
    }
    await prefs.setString('name', _name);
    await prefs.setString('email', _email);
    await prefs.setString('classes', jsonEncode(_classList));
  }

  @override
  initState() {
    super.initState();
    getExistingValues();
    getMe();
    if (!Platform.isWindows) {}
  }

  @override
  void dispose() {
    super.dispose();
    if (!Platform.isWindows) {}
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
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 18,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      "Hey $_name!",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(18.0))),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Spacer(),
                                          Text(
                                            "Bald",
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          Spacer(),
                                          Text(
                                            "4",
                                            style: TextStyle(fontSize: 70.0),
                                          ),
                                          Spacer(),
                                          Text(
                                            "Tests",
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          Spacer(),
                                        ]),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 238, 131, 81),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(18.0))),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Spacer(),
                                          Text(""),
                                          Spacer(),
                                          Text(
                                            "4",
                                            style: TextStyle(fontSize: 70.0),
                                          ),
                                          Spacer(),
                                          Text(
                                            "Hausaufgaben",
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          Spacer(),
                                        ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 49, 83, 248),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(18.0))),
                              child: Column(children: [
                                SizedBox(
                                  height: 16.0,
                                ),
                                Text(
                                  "Letzte Noten",
                                  style: TextStyle(fontSize: 20.0),
                                ),
                                Spacer(),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
