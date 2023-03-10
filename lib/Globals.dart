import 'package:notely/Models/Exam.dart';

import 'Models/Grade.dart';

String apiBase = "https://kaschuso.so.ch/public/";
String school = "";
String accessToken = "";
bool debug = false;
bool isDark = true;
List<Exam> globalExamsList = List.empty(growable: true);
int upcomingExams = 0;
