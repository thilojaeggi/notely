import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/outlined_box_shadow.dart';
import 'package:notely/pages/help_page.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:notely/secure_storage.dart';
import 'package:notely/widgets/auth_text_field.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config/style.dart';
import '../view_container.dart';

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
          debugPrint('HeadlessInAppWebView created!');
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("CONSOLE MESSAGE: ${consoleMessage.message}");
        },
        onLoadStart: (controller, url) async {
          debugPrint("onLoadStart $url");
        },
        onLoadStop: (controller, url) async {
          debugPrint("onLoadStop $url");
          if (url
              .toString()
              .contains("https://www.schul-netz.com/mobile/login?mandant")) {
            debugPrint("gotologin");
            await headlessWebView?.webViewController.evaluateJavascript(
                source:
                    """document.querySelector('.mat-raised-button').click();""");
          }
          if (url.toString().contains("authorize.php")) {
            debugPrint("authorize");
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
          debugPrint("onUpdateVisitedHistory $url");
          if (url
              .toString()
              .contains("https://www.schul-netz.com/mobile/start")) {
            debugPrint("sucessfully authenticated for the first time");
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
      apiClient.school = "demo";
      await storage.write(key: "username", value: username);
      await storage.write(key: "password", value: password);
      if (!mounted) return;
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
      debugPrint(response.statusCode.toString());
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
        if (!mounted) return;

        showToast(
          alignment: Alignment.bottomCenter,
          duration: const Duration(seconds: 1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
            ),
            padding: const EdgeInsets.all(6.0),
            child: const Text(
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
        debugPrint("Hasn't authenticated for the first time");
        await headlessWebView?.dispose();
        await headlessWebView?.run();
        headlessWebView?.webViewController.loadUrl(
            urlRequest: URLRequest(
                url: WebUri(
                    "https://www.schul-netz.com/mobile/login?mandant=https:%2F%2Fkaschuso.so.ch%2Fpublic%2F${dropdownValue.toLowerCase()}")));
      } else {
        showToast(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
            ),
            padding: const EdgeInsets.all(6.0),
            child: const Text(
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
                    Colors.black,
                    Colors.blueAccent,
                  ],
                ),
              ),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Image.asset(
                            'assets/images/notely_n.png',
                            width: 100,
                            height: 100,
                            isAntiAlias: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              OutlinedBoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 0),
                                  blurRadius: 10.0,
                                  blurStyle: BlurStyle.outer)
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: DropdownButtonFormField<String>(
                              value: dropdownValue,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                              alignment: Alignment.centerLeft,
                              decoration: const InputDecoration(
                                hintStyle: TextStyle(color: Colors.white),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.school,
                                    color: Colors.white,
                                  ),
                                ),
                                focusedBorder: InputBorder.none,
                                border: InputBorder.none,
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
                                          alignment: Alignment.centerLeft,
                                          value: value,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4.0),
                                            child: Text(
                                              description,
                                              textAlign: TextAlign.start,
                                            ),
                                          ),
                                        ));
                                  })
                                  .values
                                  .toList(),
                              dropdownColor:
                                  const Color.fromARGB(239, 72, 113, 184),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              OutlinedBoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 0),
                                  blurRadius: 10.0,
                                  blurStyle: BlurStyle.outer)
                            ],
                          ),
                          child: AuthTextField(
                            backgroundColor: Colors.transparent,
                            hintText: 'Benutzername',
                            icon: Icons.person,
                            editingController: _usernameController,
                            passwordField: false,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              OutlinedBoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 0),
                                  blurRadius: 10.0,
                                  blurStyle: BlurStyle.outer)
                            ],
                          ),
                          child: AuthTextField(
                            backgroundColor: Colors.transparent,
                            hintText: 'Passwort',
                            icon: Icons.lock,
                            editingController: _passwordController,
                            passwordField: true,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
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
                                padding: const EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
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
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Anmelden",
                                      style: TextStyle(
                                        color: _loginHasBeenPressed
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 20.0,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      CupertinoIcons.arrow_right,
                                      color: _loginHasBeenPressed
                                          ? Colors.white
                                          : Colors.black,
                                      size: 30.0,
                                    ),
                                  ],
                                ),
                              )),
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
                            builder: (context) => const HelpPage());
                      },
                      child: const Text(
                        "Hilfe?",
                        style: TextStyle(color: Colors.white, fontSize: 24.0),
                      )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox.shrink(),
      ],
    );
  }
}
