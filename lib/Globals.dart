import 'Models/Grade.dart';

String apiBase = "https://kaschuso.so.ch/public/";
String accessToken = "";
String gradeList = "";
bool debug = false;
bool isDark = true;
bool hasDynamicIsland = false;
List<Grade> globalGradeList = List.empty(growable: true);
