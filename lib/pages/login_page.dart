import 'package:flutter/foundation.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/pages/help_page.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:notely/secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  HeadlessInAppWebView? headlessWebView;
  String dropdownValue = 'KSSO';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest:
            URLRequest(url: WebUri("https://www.schul-netz.com/mobile/")),
        onWebViewCreated: (controller) {
          print('HeadlessInAppWebView created!');
        },
        onConsoleMessage: (controller, consoleMessage) {
          print("CONSOLE MESSAGE: " + consoleMessage.message);
        },
        onLoadStart: (controller, url) async {
          print("onLoadStart $url");
        },
        onLoadStop: (controller, url) async {
          print("onLoadStop $url");
          if (url
              .toString()
              .contains("https://www.schul-netz.com/mobile/login?mandant")) {
            print("gotologin");
            await headlessWebView?.webViewController.evaluateJavascript(
                source:
                    """document.querySelector('.mat-raised-button').click();""");
          }
          if (url.toString().contains("authorize.php")) {
            print("authorize");
            await headlessWebView?.webViewController
                .evaluateJavascript(source: """
                if(document.getElementById("login") && document.getElementById("passwort")){
                document.getElementById("login").value = "${_usernameController.text}"; 
                document.getElementById("passwort").value = "${_passwordController.text}"; 
                }
                document.querySelector('.login-submit').click();
                """);
          }
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) async {
          print("onUpdateVisitedHistory $url");
          if (url
              .toString()
              .contains("https://www.schul-netz.com/mobile/start")) {
            print("sucessfully authenticated for the first time");
            await headlessWebView?.dispose();
            setState(() {
              _loginHasBeenPressed = false;
            });
            signIn();
          }
        },
      );
    }
  }

  Future<void> signIn() async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    // Get text controller values
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final url = Globals.buildUrl(
        "${dropdownValue.toLowerCase()}/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl");

    if (username == "demo" && password == "demo") {
      apiClient.fakeData = true;
      await storage.write(key: "username", value: username);
      await storage.write(key: "password", value: password);
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 450),
          alignment: Alignment.bottomCenter,
          child: const ViewContainerWidget(),
        ),
      );
      return;
    } else {
      apiClient.fakeData = false;
    }

    await http.post(url, body: {
      "login": username,
      "passwort": password,
    }, headers: {
      'accept-encoding': 'gzip, deflate',
      'access-control-allow-credentials': 'true',
      'access-control-allow-headers': '*',
      'access-control-allow-methods': '*',
      'access-control-allow-origin': '*',
      'access-control-expose-headers': '*'
    }).then((response) async {
      print(response.statusCode);
      if (response.statusCode == 302 && response.headers['location'] != null) {
        String locationHeader = response.headers['location'].toString();
        var trimmedString =
            locationHeader.substring(0, locationHeader.indexOf('&'));
        trimmedString = trimmedString
            .substring(trimmedString.indexOf("#") + 1)
            .replaceAll("access_token=", "");
        final prefs = await SharedPreferences.getInstance();
        await storage.write(key: "username", value: username);
        await storage.write(key: "password", value: password);
        await prefs.setString("school", dropdownValue.toLowerCase());

        apiClient.accessToken = trimmedString;
        apiClient.school = dropdownValue.toLowerCase();
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
        print("Hasn't authenticated for the first time");
        await headlessWebView?.dispose();
        await headlessWebView?.run();
        headlessWebView?.webViewController.loadUrl(
            urlRequest: URLRequest(
                url: WebUri(
                    "https://www.schul-netz.com/mobile/login?mandant=https:%2F%2Fkaschuso.so.ch%2Fpublic%2F" +
                        dropdownValue.toLowerCase())));
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
    return Stack(
      children: [
        Scaffold(
          body: Theme(
            data: Styles.themeData(true, context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    Color.fromARGB(255, 40, 40, 40),
                    Color.fromARGB(255, 10, 10, 10),
                  ])),
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
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            )),
                        Card(
                          color: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonFormField2<String>(
                            value: dropdownValue,
                            selectedItemHighlightColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              hintStyle: TextStyle(color: Colors.white),
                              prefixIcon: Icon(
                                Icons.school,
                                color: Colors.white,
                              ),
                              contentPadding: EdgeInsets.only(
                                  top: 19.0, bottom: 19.0, right: 19.0),
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
                              'KBS Olten': 'KBSOL',
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
                          backgroundColor: Colors.transparent,
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
                          backgroundColor: Colors.transparent,
                          hintText: 'Passwort',
                          icon: Icons.lock,
                          editingController: _passwordController,
                          passwordField: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: OutlinedButton(
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _loginHasBeenPressed = true;
                              });
                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                              signIn();
                            },
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.fromLTRB(15, 10, 15, 10),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              side: BorderSide(
                                  width: 3.0,
                                  color: _loginHasBeenPressed
                                      ? Colors.white
                                      : Colors.transparent),
                              backgroundColor: _loginHasBeenPressed
                                  ? Colors.transparent
                                  : Colors.white,
                              animationDuration: const Duration(
                                milliseconds: 450,
                              ),
                            ),
                            child: Text(
                              'Anmelden',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 28,
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
                  TextButton(
                      style: TextButton.styleFrom(
                          splashFactory: NoSplash.splashFactory),
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => HelpPage());
                      },
                      child: Text(
                        "Hilfe?",
                        style: TextStyle(color: Colors.white, fontSize: 24.0),
                      )),
                ],
              ),
            ),
          ),
        ),
        SizedBox.shrink(),
      ],
    );
  }
}
