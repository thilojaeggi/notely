import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../config/Globals.dart' as Globals;
import '../config/style.dart';
import '../view_container.dart';
import '../widgets/AuthTextField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loginHasBeenPressed = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String dropdownValue = 'KSSO';

  Future<void> signIn() async {
    const storage = FlutterSecureStorage();
    String url = Globals.apiBase +
        "${dropdownValue.toLowerCase()}/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl";
    print(url);
    await http.post(Uri.parse(url), body: {
      "login": _usernameController.text,
      "passwort": _passwordController.text,
    }).then((response) async {
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
        await prefs.setString("school", dropdownValue.toLowerCase());
        Globals.accessToken = trimmedString;
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
        child: Theme(
          data: Styles.themeData(true, context),
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
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
                          items: <String, String>{
                            'Kanti Solothurn': 'KSSO',
                            'GIBS Solothurn': 'GIBSSO',
                            'KBS Solothurn': 'KBSSO',
                            'GIBS Grenchen': 'GIBSGR',
                            'GIBS Olten': 'GIBSOL',
                            'Kanti Olten': 'KSOL',
                          }
                              .map((description, value) {
                                return MapEntry(
                                    description,
                                    DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(description),
                                    ));
                              })
                              .values
                              .toList(),
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
                            FocusManager.instance.primaryFocus?.unfocus();
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
      ),
    );
  }
}
