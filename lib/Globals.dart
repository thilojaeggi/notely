import 'package:notely/Models/Exam.dart';

class Globals {
  static final Globals _singleton = Globals._internal();

  factory Globals() {
    return _singleton;
  }

  Globals._internal();

  String apiBase = "https://kaschuso.so.ch/public/";
  String school = "";
  String accessToken = "";
  bool debug = false;
  bool isDark = true;
  List<Exam> globalExamsList = List.empty(growable: true);
}
