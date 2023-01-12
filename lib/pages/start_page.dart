import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:notely/Models/Exam.dart';
import 'package:notely/pages/exams_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Globals.dart' as Globals;
import '../Models/Grade.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

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

  Future<void> getGrades() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "ksso";
    String url =
        Globals.apiBase + school.toLowerCase() + "/rest/v1" + "/me/grades";
    if (Globals.debug) {
      url = "https://api.mocki.io/v2/e3516d96/grades";
    }
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        if (mounted) {
          setState(() {
            Globals.globalGradeList = (json.decode(response.body) as List)
                .map((i) => Grade.fromJson(i))
                .toList();
          });
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> getExams() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "ksso";
    String url =
        Globals.apiBase + school.toLowerCase() + "/rest/v1" + "/me/exams";

    int newExamCount = 0;
    List<Exam> newExamsList = List.empty(growable: true);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        final data = jsonDecode(response.body);
        for (Map<String, dynamic> i in data) {
          DateTime tempDate =
              new DateFormat("yyyy-MM-dd").parse(i["startDate"]);
          if (tempDate.isAfter(DateTime.now())) {
            print(Exam.fromJson(i).startDate);
            newExamsList.add(Exam.fromJson(i));
            if (tempDate
                .isBefore(DateTime.now().add(const Duration(days: 14)))) {
              if (mounted) {
                setState(() {
                  newExamCount++;
                });
              }
            }
          }
        }
        newExamsList.sort((a, b) {
          return DateTime.parse(a.startDate ?? "")
              .compareTo(DateTime.parse(b.startDate ?? ""));
        });
        setState(() {
          Globals.upcomingExams = newExamCount;
          Globals.globalExamsList = newExamsList;
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  initState() {
    super.initState();
    getExistingValues();
    getMe();
    getGrades();
    getExams();
    print(Globals.globalExamsList.length.toString());
  }

  @override
  void dispose() {
    super.dispose();
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
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => ExamsPage());
                                    },
                                    customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                    child: Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        border: Border.all(
                                            color: Colors.grey.withOpacity(0.5),
                                            width: 2.0),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(18.0)),
                                      ),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Spacer(),
                                            Text(
                                              "Bald",
                                              style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Spacer(),
                                            Text(
                                              Globals.upcomingExams.toString(),
                                              style: TextStyle(fontSize: 80.0),
                                            ),
                                            Spacer(),
                                            Text(
                                              "Tests",
                                              style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Spacer(),
                                          ]),
                                    ),
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
                                          style: TextStyle(fontSize: 80.0),
                                        ),
                                        Spacer(),
                                        Text(
                                          "Hausaufgaben",
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Spacer(),
                                      ],
                                    ),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18.0),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 49, 83, 248),
                                  borderRadius: BorderRadius.circular(18.0),
                                  border: Border.all(
                                      color: Colors.blue.withOpacity(0.5),
                                      width: 2.0),
                                ),
                                child: Column(children: [
                                  SizedBox(
                                    height: 16.0,
                                  ),
                                  Text(
                                    "Neueste Noten",
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                        padding: const EdgeInsets.only(
                                            left: 10.0, right: 10.0),
                                        itemCount:
                                            Globals.globalGradeList.length,
                                        shrinkWrap: true,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return Container(
                                            margin: (index == 99)
                                                ? EdgeInsets.only(bottom: 9.0)
                                                : (index == 0)
                                                    ? EdgeInsets.only(
                                                        top: 8.0, bottom: 3.0)
                                                    : EdgeInsets.only(
                                                        bottom: 3.0),
                                            width: double.infinity,
                                            padding: EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.only(
                                                topLeft: (index == 0)
                                                    ? Radius.circular(12.0)
                                                    : Radius.circular(5.0),
                                                topRight: (index == 0)
                                                    ? Radius.circular(12.0)
                                                    : Radius.circular(5.0),
                                                bottomLeft: (index ==
                                                        Globals.globalGradeList
                                                                .length -
                                                            1)
                                                    ? Radius.circular(12.0)
                                                    : Radius.circular(5.0),
                                                bottomRight: (index ==
                                                        Globals.globalGradeList
                                                                .length -
                                                            1)
                                                    ? Radius.circular(12.0)
                                                    : Radius.circular(5.0),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    "Note: " +
                                                        Globals
                                                            .globalGradeList[
                                                                index]
                                                            .mark
                                                            .toString(),
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                                Expanded(
                                                    child: AutoSizeText(
                                                  Globals.globalGradeList[index]
                                                      .title
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )),
                                              ],
                                            ),
                                          );
                                        }),
                                  ),
                                ]),
                              ),
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
