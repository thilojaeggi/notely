import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:schulnetz/AuthTextField.dart';
import 'package:schulnetz/view_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loginHasBeenPressed = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String dropdownValue = 'GIBSSO';

  Future<String> getCookie(http.Response response) async {
    Map<String, String> headers = {};
    String? rawCookie = response.headers['set-cookie'] as String?;
    if (rawCookie != null) {
      return rawCookie
          .toString()
          .replaceAll("path=/,", "")
          .replaceAll("path=/; Secure; HttpOnly", "");
    } else {
      return "";
    }
  }

  Future<void> signIn() async {
    const storage = FlutterSecureStorage();
    await http.post(
        Uri.parse(
            "https://kaschuso.so.ch/public/${dropdownValue.toLowerCase()}/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl&redirect_uri=https://www.schul-netz.com/mobile/oauth-callback.html&id="),
        body: {
          "login": _usernameController.text,
          "passwort": _passwordController.text,
        }).then((response) async {
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 302 && response.headers['location'] != null) {
        String locationHeader = response.headers['location'].toString();

        var trimmedString =
            locationHeader.substring(0, locationHeader.indexOf('&'));
        trimmedString = trimmedString
            .substring(trimmedString.indexOf("#") + 1)
            .replaceAll("access_token=", "");
        final prefs = await SharedPreferences.getInstance();
        storage.write(key: "username", value: _usernameController.text);
        storage.write(key: "password", value: _passwordController.text);
        await prefs.setString("school", dropdownValue);
        await prefs.setString("accessToken", trimmedString);
        showToast(
          alignment: Alignment.bottomCenter,
          duration: Duration(seconds: 1),
          child: Container(
            margin: EdgeInsets.only(bottom: 32.0),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
            ),
            padding: EdgeInsets.all(6.0),
            child: Text(
              "Erfolgreich angemeldet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
          ),
          context: context,
        );
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 450),
            alignment: Alignment.bottomCenter,
            child: const ViewContainerWidget(),
          ),
        );
      } else if (response.statusCode == 200 &&
          response.headers['location'] == null) {
        String cookies = await getCookie(response);
        print(cookies);

        String allowAppRequest = parse(response.body)
            .getElementsByTagName("form")
            .first
            .attributes['action']
            .toString();
        print("https://kaschuso.so.ch/public/${dropdownValue.toLowerCase()}/" +
            allowAppRequest);
        await http
            .post(
          Uri.parse(
              "https://kaschuso.so.ch/public/${dropdownValue.toLowerCase()}/" +
                  allowAppRequest),
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "Cookies": cookies,
          },
          body: "authorized=yes",
        )
            .then((response) async {
          if (response.statusCode == 200) {
            print(response.body);
            /*signIn();
            showToast(
          alignment: Alignment.bottomCenter,
          duration: Duration(seconds: 1),
          child: Container(
            margin: EdgeInsets.only(bottom: 32.0),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
            ),
            padding: EdgeInsets.all(6.0),
            child: Text(
              "Erfolgreich angemeldet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
          ),
          context: context,
        );*/
          } else {
            showToast(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 32.0),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(
                    Radius.circular(12.0),
                  ),
                ),
                padding: EdgeInsets.all(6.0),
                child: Text(
                  "Etwas ist schiefgelaufen",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              context: context,
            );
            setState(() {
              _loginHasBeenPressed = false;
            });
          }
        });
      } else {
        showToast(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(bottom: 32.0),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
            ),
            padding: EdgeInsets.all(6.0),
            child: Text(
              "Etwas ist schiefgelaufen",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
          ),
          context: context,
        );
        setState(() {
          _loginHasBeenPressed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Notely",
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.start,
                        )),
                    const SizedBox(
                      height: 5,
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonFormField2<String>(
                        value: dropdownValue,
                        selectedItemHighlightColor: Colors.black,
                        focusColor: Colors.transparent,
                        icon: const Icon(Icons.arrow_downward),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(
                            Icons.school,
                            color: Colors.white,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            ),
                            borderSide:
                                BorderSide(color: Colors.white, width: 4.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            ),
                            borderSide:
                                BorderSide(color: Colors.white, width: 2.5),
                          ),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue = newValue!;
                          });
                        },
                        items: <String>['GIBSSO', 'KBSSO', 'KSSO']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    AuthTextField(
                      hintText: 'Benutzername',
                      icon: Icons.person,
                      editingController: _usernameController,
                      passwordField: false,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    AuthTextField(
                      hintText: 'Passwort',
                      icon: Icons.lock,
                      editingController: _passwordController,
                      passwordField: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () async {
                          setState(() {
                            _loginHasBeenPressed = true;
                          });
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          signIn();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          side: BorderSide(
                              width: 2.0,
                              color: _loginHasBeenPressed
                                  ? Colors.white
                                  : Colors.black),
                          backgroundColor: _loginHasBeenPressed
                              ? Colors.black
                              : Colors.white,
                          animationDuration: const Duration(
                            milliseconds: 450,
                          ),
                        ),
                        child: Text(
                          'Anmelden',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: _loginHasBeenPressed
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
