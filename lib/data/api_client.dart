import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notely/features/auth/token_manager.dart';
import 'package:notely/models/absence.dart';
import 'package:notely/models/event.dart';
import 'package:notely/models/exam.dart';
import 'package:notely/models/grade.dart';

import 'package:notely/data/demo_data.dart';
import 'package:notely/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIClient {
  static final APIClient _singleton = APIClient._internal();
  static const String _baseUrl = 'https://kaschuso.so.ch/public';
  late String _accessToken;
  late String school;
  bool _fakeData = false;
  final TokenManager _tokenManager = TokenManager();

  factory APIClient() {
    return _singleton;
  }

  APIClient._internal();

  set accessToken(String accessToken) {
    _accessToken = accessToken;
  }

  set fakeData(bool fakeData) {
    _fakeData = fakeData;
  }

  dynamic getDemoData(String path) {
    return DemoDataProvider.getDemoData(path);
  }

  Future<bool> isAccessTokenValid(String token, String targetSchool) async {
    if (token.isEmpty || targetSchool.isEmpty) {
      return false;
    }
    try {
      final urlString = '$_baseUrl/$targetSchool/rest/v1/me';
      final finalUrl =
          kIsWeb ? 'https://lite.corsfix.com/?$urlString' : urlString;
      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 && !response.body.contains('<html>');
    } catch (e) {
      debugPrint('isAccessTokenValid error: $e');
      return false;
    }
  }

  Future<void> _ensureValidAccessToken(SharedPreferences prefs) async {
    if (_fakeData) {
      return;
    }
    var targetSchool = school;
    if (targetSchool.isEmpty) {
      targetSchool = (prefs.getString("school") ?? "").toLowerCase();
      school = targetSchool;
    }
    if (targetSchool.isEmpty) {
      throw Exception('Daten konnten nicht geladen werden');
    }
    final freshToken = await _tokenManager.getValidAccessToken(targetSchool);
    if (freshToken == null || freshToken.isEmpty) {
      throw Exception('Anmeldung erforderlich');
    }
    _accessToken = freshToken;
  }

  Future<T> get<T>(
      String path, T Function(dynamic) fromJson, bool cached) async {
    final prefs = await SharedPreferences.getInstance();
    if (_fakeData) {
      debugPrint('getDemoData: _fakeData is true, path: $path');
      final demoData = getDemoData(path);
      debugPrint(
          'getDemoData: returned data type: ${demoData?.runtimeType}, is null: ${demoData == null}');
      // If demoData is null or doesn't match the expected path, return empty result
      if (demoData == null) {
        debugPrint('getDemoData: demoData is null for path: $path');
        // Return appropriate empty result based on type
        if (path.contains('events') ||
            path.contains('exams') ||
            path.contains('grades') ||
            path.contains('absencenotices')) {
          // Return empty list cast to T (T should be List<Something>)
          return [] as T;
        }
        throw Exception('Demo data not available for path: $path');
      }
      return demoData as T;
    }
    await _ensureValidAccessToken(prefs);
    if (cached) {
      // Get cached data from shared preferences
      final cachedData = (!path.contains("events"))
          ? prefs.getString(path)
          : prefs.getString('events');

      if (cachedData != null) {
        if (cachedData.contains('<html>')) {
          prefs.remove(path);
          prefs.remove('events');
          return get(path, fromJson, cached);
        }
        return fromJson(json.decode(cachedData));
      }
    }
    final urlString = '$_baseUrl/$school$path';
    final finalUrl =
        kIsWeb ? 'https://lite.corsfix.com/?$urlString' : urlString;
    final response = await http.get(Uri.parse(finalUrl),
        headers: {'Authorization': 'Bearer $_accessToken'});
    if (response.statusCode == 200 && !response.body.contains("<html>")) {
      // Cache data in shared preferences
      (!path.contains("events"))
          ? prefs.setString(path, response.body)
          : prefs.setString('events', response.body);

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
          .where((e) =>
              e.startDate.isAfter(today.subtract(const Duration(days: 1))))
          .toList();
    }, cached);
  }

  Future<List<Event>> getEvents(DateTime date, bool cached) async {
    final dateFormatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

      List<Grade> grades =
          (json as List<dynamic>).map((e) => Grade.fromJson(e)).toList();

      grades = grades
          .where((grade) => grade.mark != null && grade.mark != 0)
          .toList();

      return grades;
    }, cached);
  }

  Future<Student> getStudent(bool cached) async {
    return get('/rest/v1/me', (json) => Student.fromJson(json), cached);
  }
}
