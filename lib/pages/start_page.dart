import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:notely/helpers/api_client.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:notely/Models/Exam.dart';
import 'package:notely/Models/Homework.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';
import 'package:notely/pages/exams_page.dart';
import 'package:notely/pages/homework_page.dart';

import '../Models/Grade.dart';
import '../Models/Student.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final APIClient _apiClient = APIClient();
  List<Exam> exams = <Exam>[];
  // Make cards half approx. height of screen
  double get cardHeight => MediaQuery.of(context).size.height / 5;
  late Future<List<Homework>> homeworkFuture;

  StreamController<List<Grade>> _gradesStreamController =
      StreamController<List<Grade>>();

  StreamController<Student> _studentStreamController =
      StreamController<Student>();

  StreamController<List<Exam>> _examsStreamController =
      StreamController<List<Exam>>();

  void _getGrades() async {
    if (!mounted) return;

    try {
      List<Grade> cachedGrades = await _apiClient.getGrades(true);
      _gradesStreamController.sink.add(cachedGrades);

      // Then get the latest data and update the UI again
      List<Grade> latestGrades = await _apiClient.getGrades(false);
      _gradesStreamController.sink.add(latestGrades);
    } catch (e) {
      // Handle the StateError here
      print('Error adding event to stream controller: $e');
    }
  }

  void _getStudent() async {
    if (!mounted) return;

    try {
      Student cachedStudent = await _apiClient.getStudent(true);
      _studentStreamController.sink.add(cachedStudent);

      // Then get the latest data and update the UI again
      Student latestStudent = await _apiClient.getStudent(false);
      _studentStreamController.sink.add(latestStudent);
    } catch (e) {
      // Handle the StateError here
      print('Error adding event to stream controller: $e');
    }
  }

  void _getExams() async {
    if (!mounted) return;
    try {
      List<Exam> cachedExams = await _apiClient.getExams(true);
      _examsStreamController.sink.add(cachedExams);
      exams = cachedExams;

      // Then get the latest data and update the UI again
      List<Exam> latestExams = await _apiClient.getExams(false);
      _examsStreamController.sink.add(latestExams);
      exams = latestExams;
      exams.sort((a, b) => a.startDate.compareTo(b.startDate));

    } catch (e) {
      // Handle the StateError here
      print('Error adding event to stream controller: $e');
    }
  }

  @override
  void dispose() {
    _gradesStreamController.close();
    _studentStreamController.close();
    _examsStreamController.close();
    super.dispose();
  }

  List<Homework> homeworkList = <Homework>[];
  final Random random = Random();

  static const List<String> hellos = [
    "Hoi",
    "Sali",
    "Ciao",
    "Hallo",
    "Salut",
    "Hey",
  ];
  int randomHelloIndex = 0;

  void homeworkCallback(List<Homework> homework) {
    setState(() {
      homeworkList = homework;
    });
  }

  Future<List<Homework>> getHomework() async {
    List<Homework> homeworkList = await HomeworkDatabase.instance.readAll();
    homeworkList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return homeworkList;
  }

  @override
  initState() {
    super.initState();

    _getGrades();
    _getStudent();
    _getExams();

    homeworkFuture = getHomework();
    randomHelloIndex = random.nextInt(hellos.length);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder<Student?>(
                  stream: _studentStreamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error"),
                      );
                    }
                    Student? student = snapshot.data;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();

                                          showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (context) => ExamsPage(
                                                    examList: exams,
                                                  ));
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
                                            StreamBuilder<List<Exam>>(
                                                stream: _examsStreamController
                                                    .stream,
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return const Center(
                                                      child: Text("Error"),
                                                    );
                                                  }
                                                  List<Exam> exams =
                                                      snapshot.data!;

                                                  int examCount = 0;
                                                  for (var exam in exams) {
                                                    if (exam.startDate.isBefore(
                                                        DateTime.now().add(
                                                            const Duration(
                                                                days: 14)))) {
                                                      examCount++;
                                                    }
                                                  }
                                                  return FittedBox(
                                                    child: Text(
                                                      examCount.toString(),
                                                      style: TextStyle(
                                                        fontSize: 48,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    fit: BoxFit.scaleDown,
                                                  );
                                                }),
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
                                        HapticFeedback.selectionClick();
                                        showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => FutureBuilder<
                                                    List<Homework>>(
                                                future: homeworkFuture,
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return const Center(
                                                      child: Text("Error"),
                                                    );
                                                  }
                                                  List<Homework> homework =
                                                      snapshot.data!;
                                                  return HomeworkPage(
                                                      homeworkList: homework,
                                                      callBack:
                                                          homeworkCallback);
                                                }));
                                      },
                                      customBorder: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            FutureBuilder<List<Homework>>(
                                                future: homeworkFuture,
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return const Center(
                                                      child: Text("Error"),
                                                    );
                                                  }
                                                  List<Homework> homework =
                                                      snapshot.data!;
                                                  int homeworkCount = 0;
                                                  for (var homeworkItem
                                                      in homework) {
                                                    if (!homeworkItem.isDone) {
                                                      homeworkCount++;
                                                    }
                                                  }
                                                  return FittedBox(
                                                    child: Text(
                                                      homeworkCount.toString(),
                                                      style: TextStyle(
                                                        fontSize: 48,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    fit: BoxFit.scaleDown,
                                                  );
                                                }),
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
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.blue.shade800,
                                          Colors.blue.shade500,
                                          Colors.blue.shade300,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10.0),
                                            child: Text(
                                              "Neueste Noten",
                                              style: TextStyle(
                                                fontSize: 20.0,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: StreamBuilder<List<Grade>?>(
                                              stream: _gradesStreamController
                                                  .stream,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return const Center(
                                                    child: Text("Error"),
                                                  );
                                                }
                                                List<Grade>? gradeList =
                                                    snapshot.data!
                                                        .take(7)
                                                        .toList();
                                                return ListView.builder(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10.0,
                                                          right: 10.0),
                                                  itemCount: gradeList.length,
                                                  shrinkWrap: true,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    return Container(
                                                      margin: (index ==
                                                              gradeList.length -
                                                                  1)
                                                          ? EdgeInsets.only(
                                                              bottom: 11.0)
                                                          : (index == 0)
                                                              ? EdgeInsets.only(
                                                                  top: 8.0,
                                                                  bottom: 3.0)
                                                              : EdgeInsets.only(
                                                                  bottom: 3.0),
                                                      width: double.infinity,
                                                      padding:
                                                          EdgeInsets.all(12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.only(
                                                          topLeft: (index == 0)
                                                              ? Radius.circular(
                                                                  8.0)
                                                              : Radius.circular(
                                                                  4.0),
                                                          topRight: (index == 0)
                                                              ? Radius.circular(
                                                                  8.0)
                                                              : Radius.circular(
                                                                  4.0),
                                                          bottomLeft: (index ==
                                                                  gradeList
                                                                          .length -
                                                                      1)
                                                              ? Radius.circular(
                                                                  6.0)
                                                              : Radius.circular(
                                                                  4.0),
                                                          bottomRight: (index ==
                                                                  gradeList
                                                                          .length -
                                                                      1)
                                                              ? Radius.circular(
                                                                  6.0)
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
                                                              flex: 7,
                                                              child:
                                                                  AutoSizeText(
                                                                gradeList[index]
                                                                    .title
                                                                    .toString(),
                                                                style:
                                                                    TextStyle(
                                                                  height: 1.0,
                                                                  fontSize: 15,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              )),
                                                          Expanded(
                                                            flex: 4,
                                                            child: Text(
                                                              "Note: " +
                                                                  gradeList[
                                                                          index]
                                                                      .mark
                                                                      .toString(),
                                                              style: TextStyle(
                                                                height: 1.0,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
