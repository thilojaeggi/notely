import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
import '../Models/Student.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final double cardHeight = 150; // Define the height for the cards

  final List<String> hellos = ["Hoi", "Sali", "Ciao", "Hallo", "Salut", "Hey"];
  final Random random = Random();
  List<Exam> _examList = <Exam>[];

  Future<Student?> getMe() async {
    final url = "${Globals.apiBase}${Globals.school.toLowerCase()}/rest/v1/me";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${Globals.accessToken}'},
      );
      print(response.body);

      final student = Student.fromJson(jsonDecode(response.body));
      return student;
    } catch (e) {
      print('Error getting student: $e');
    }

    return null;
  }

  Future<List<Grade>> getGrades() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "ksso";
    String url =
        Globals.apiBase + school.toLowerCase() + "/rest/v1" + "/me/grades";
    List<Grade> gradeList = <Grade>[];
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        gradeList = jsonDecode(response.body)
            .map<Grade>((json) => Grade.fromJson(json))
            .toList()
            .reversed
            .take(7)
            .toList();
      });
    } catch (e) {
      print(e.toString());
    }
    return gradeList;
  }

  Future<List<Exam>> getExams() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "ksso";
    String url =
        Globals.apiBase + school.toLowerCase() + "/rest/v1" + "/me/exams";

    List<Exam> examsList = <Exam>[];
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        examsList = ExamFromJson(response.body);
        examsList.sort((a, b) {
          return a.startDate.compareTo(b.startDate);
        });
        _examList = examsList;
      });
    } catch (e) {
      print(e.toString());
    }
    return examsList;
  }

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int randomHelloIndex = random.nextInt(hellos.length);
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
                  child: FutureBuilder<Student?>(
                      future: getMe(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error"),
                          );
                        }
                        Student? student = snapshot.data;
                        print(student);
                        String? firstName = student?.firstName?.split(' ')[0];
                        return Text(
                          "${hellos[randomHelloIndex]} ${firstName ?? "..."}!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.start,
                        );
                      }),
                ),
                IntrinsicHeight(
                  child: Container(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 8,
                          child: Column(
                            children: [
                              SizedBox(
                                height: cardHeight,
                                width: double.infinity,
                                child: Container(
                                  child: Card(
                                    elevation: 3.0,
                                    shadowColor: Colors.grey.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                ExamsPage(examList: _examList));
                                      },
                                      customBorder: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          FittedBox(
                                            child: Text(
                                              'Bald',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            fit: BoxFit.scaleDown,
                                          ),
                                          FittedBox(
                                            child: Text(
                                              '69',
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            fit: BoxFit.scaleDown,
                                          ),
                                          FittedBox(
                                            child: Text(
                                              'Tests',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: cardHeight,
                                width: double.infinity,
                                child: Card(
                                  elevation: 3.0,
                                  shadowColor: Colors.grey.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              ExamsPage(examList: _examList));
                                    },
                                    customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          FittedBox(
                                            child: Text(
                                              '8',
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            fit: BoxFit.scaleDown,
                                          ),
                                          FittedBox(
                                            child: Text(
                                              'Hausaufgaben',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: SizedBox(
                              height: cardHeight * 2,
                              child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromARGB(255, 49, 83, 248),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              "Neueste Noten",
                                              style: TextStyle(
                                                fontSize: 20.0,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Expanded(
                                              child:
                                                  FutureBuilder<List<Grade>?>(
                                                      future: getGrades(),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return const Center(
                                                            child:
                                                                Text("Error"),
                                                          );
                                                        }
                                                        List<Grade>? gradeList =
                                                            snapshot.data;
                                                        return ListView.builder(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 10.0,
                                                                    right:
                                                                        10.0),
                                                            itemCount:
                                                                gradeList!
                                                                    .length,
                                                            shrinkWrap: true,
                                                            itemBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              return Container(
                                                                margin: (index ==
                                                                        gradeList.length -
                                                                            1)
                                                                    ? EdgeInsets.only(
                                                                        bottom:
                                                                            10.0)
                                                                    : (index ==
                                                                            0)
                                                                        ? EdgeInsets.only(
                                                                            top:
                                                                                8.0,
                                                                            bottom:
                                                                                3.0)
                                                                        : EdgeInsets.only(
                                                                            bottom:
                                                                                3.0),
                                                                width: double
                                                                    .infinity,
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            12.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .only(
                                                                    topLeft: (index ==
                                                                            0)
                                                                        ? Radius.circular(
                                                                            8.0)
                                                                        : Radius.circular(
                                                                            4.0),
                                                                    topRight: (index ==
                                                                            0)
                                                                        ? Radius.circular(
                                                                            8.0)
                                                                        : Radius.circular(
                                                                            4.0),
                                                                    bottomLeft: (index ==
                                                                            gradeList!.length -
                                                                                1)
                                                                        ? Radius.circular(
                                                                            8.0)
                                                                        : Radius.circular(
                                                                            4.0),
                                                                    bottomRight: (index ==
                                                                            gradeList.length -
                                                                                1)
                                                                        ? Radius.circular(
                                                                            8.0)
                                                                        : Radius.circular(
                                                                            4.0),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                        child:
                                                                            AutoSizeText(
                                                                      gradeList[
                                                                              index]
                                                                          .title
                                                                          .toString(),
                                                                      style:
                                                                          TextStyle(
                                                                        height:
                                                                            1.0,
                                                                        fontSize:
                                                                            15,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    )),
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        "Note: " +
                                                                            gradeList[index].mark.toString(),
                                                                        style: TextStyle(
                                                                            height:
                                                                                1.0,
                                                                            fontSize:
                                                                                16,
                                                                            color:
                                                                                Colors.white,
                                                                            fontWeight: FontWeight.w400),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            });
                                                      }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    ));
  }
}
