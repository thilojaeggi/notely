import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notely/Models/Absence.dart';
import 'package:notely/Models/Event.dart';
import 'package:notely/Models/Exam.dart';
import 'package:notely/Models/Grade.dart';
import 'package:notely/Models/Student.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIClient {
  static final APIClient _singleton = APIClient._internal();
  static const String _baseUrl = 'https://kaschuso.so.ch/public';
  late String _accessToken;
  late String _school;

  factory APIClient() {
    return _singleton;
  }

  APIClient._internal();

  set accessToken(String accessToken) {
    _accessToken = accessToken;
  }

  set school(String school) {
    _school = school;
  }

  String get school => _school;

  Future<T> get<T>(
      String path, T Function(dynamic) fromJson, bool cached) async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken.isEmpty || _school.isEmpty) {
      throw Exception('Daten konnten nicht geladen werden');
    }
    if (cached) {
      // Get cached data from shared preferences
      final cachedData = (!path.contains("events"))
          ? prefs.getString('$path')
          : prefs.getString('events');

      if (cachedData != null) {
        return fromJson(json.decode(cachedData));
      }
    }
    final response = await http.get(Uri.parse('$_baseUrl/$_school$path'),
        headers: {'Authorization': 'Bearer $_accessToken'});
    if (response.statusCode == 200) {
      // Cache data in shared preferences

      (!path.contains("events"))
          ?  prefs.setString('$path', response.body)
          :  prefs.setString('events', response.body);

      return fromJson(json.decode(response.body));
    } else {
      throw Exception('Daten konnten nicht geladen werden');
    }
  }

  Future<List<Absence>> getAbsences(bool cached) async {
    return get(
        '/rest/v1/me/absencenotices',
        (json) =>
            (json as List<dynamic>).map((e) => Absence.fromJson(e)).toList(),
        cached);
  }

  Future<List<Exam>> getExams(bool cached) async {
    return get('/rest/v1/me/exams', (json) {
      // Only return exams after today
      final today = DateTime.now();
      return (json as List<dynamic>)
          .map((e) => Exam.fromJson(e))
          .where((e) => e.startDate.isAfter(today))
          .toList();
    }, cached);
  }

  Future<List<Event>> getEvents(DateTime date, bool cached) async {
    final dateFormatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    print(dateFormatted);
    return get(
        '/rest/v1/me/events?min_date=$dateFormatted&max_date=$dateFormatted',
        (json) {
      return (json as List<dynamic>).map((e) => Event.fromJson(e)).toList();
    }, cached);
  }

  Future<List<Grade>> getGrades(bool cached) async {
    return get('/rest/v1/me/grades', (json) {
      // store in shared preferences
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString("grades", jsonEncode(json));
      });

      return (json as List<dynamic>).map((e) => Grade.fromJson(e)).toList();
    }, cached);
  }

  Future<Student> getStudent(bool cached) async {
    return get('/rest/v1/me', (json) => Student.fromJson(json), cached);
  }
}
