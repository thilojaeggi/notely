import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schulnetz/Globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  String _education = "";
  final storage = const FlutterSecureStorage();
  Map<String, dynamic> _user = Map();

  Future<void> getExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getString('name') ?? "");
    if (mounted) {
      setState(() {
        _name = prefs.getString('name') ?? "";
        _email = prefs.getString('email') ?? "";
        _education = prefs.getString('education') ?? "";
      });
    }
  }

  Future<void> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    String username = await storage.read(key: "username") as String;
    String password = await storage.read(key: "password") as String;
    String school = await prefs.getString("school") ?? "ksso";
    print(school);
    String url = Globals.apiBase +
        "user/info?mandator=" +
        school.toLowerCase() +
        "&username=" +
        username +
        "&password=" +
        password;
    print(url);
    try {
      await http.get(Uri.parse(url)).then((response) {
        print(response.body);
        if (response.statusCode == 200) {
          _user = jsonDecode(response.body);
        }
      });
    } catch (e) {
      print(e.toString());
    }

    if (mounted) {
      setState(() {
        _name = _user['userInfo']['name'];
        _email = _user['userInfo']['email'];
        _education = _user['userInfo']['education'];
      });
    }
    await prefs.setString('name', _user['userInfo']['name']);
    await prefs.setString('email', _user['userInfo']['email']);
    await prefs.setString('education', _user['userInfo']['education']);
  }

  @override
  initState() {
    super.initState();
    getExistingData();
    getMe();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      height: double.infinity,
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
            height: 40,
          ),
          Text(
            _education,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
