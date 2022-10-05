import 'package:notely/Models/Exam.dart';

import 'Models/Grade.dart';

String apiBase = "https://kaschuso.so.ch/public/";
String accessToken = "";
String gradeList = "";
bool debug = false;
bool isDark = true;
bool hasDynamicIsland = false;
List<Grade> globalGradeList = List.empty(growable: true);
List<Exam> globalExamsList = List.empty(growable: true);
int upcomingExams = 0;
