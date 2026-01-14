import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notely/helpers/token_manager.dart';
import 'package:notely/models/absence.dart';
import 'package:notely/models/Event.dart';
import 'package:notely/models/exam.dart';
import 'package:notely/models/grade.dart';

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
    if (path.contains("events")) {
      // Parse date from path if available, otherwise use today
      DateTime targetDate = DateTime.now();
      try {
        final dateMatch =
            RegExp(r'min_date=(\d{4}-\d{2}-\d{2})').firstMatch(path);
        if (dateMatch != null) {
          final dateStr = dateMatch.group(1)!;
          final parts = dateStr.split('-');
          targetDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (e) {
        // If parsing fails, use today
        targetDate = DateTime.now();
      }

      return [
        Event(
            id: 'demo-event-1',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 7, 45),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 8, 35),
            text: 'Mathematik',
            comment: 'Analytische Geometrie - Aufgabenblock C',
            roomToken: 'B215',
            roomId: 'B215',
            teachers: ['Patrick Keller'],
            teacherIds: ['teacher-1'],
            teacherTokens: ['teacher-token-1'],
            courseId: 'course-1',
            courseToken: 'math-token',
            courseName: 'Mathematik Schwerpunkt',
            status: 'confirmed',
            color: '#3366CC',
            eventType: 'lesson',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-2',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 8, 40),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 9, 30),
            text: 'Deutsch',
            comment: 'Textanalyse zu Dürrenmatt, bring Heft mit',
            roomToken: 'A112',
            roomId: 'A112',
            teachers: ['Claudia Messerli'],
            teacherIds: ['teacher-2'],
            teacherTokens: ['teacher-token-2'],
            courseId: 'course-2',
            courseToken: 'deutsch-token',
            courseName: 'Deutsch LZ 3',
            status: 'confirmed',
            color: '#2E8B57',
            eventType: 'lesson',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-3',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 9, 45),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 10, 35),
            text: 'English',
            comment: 'Debate preparation - sustainability topic',
            roomToken: 'C05',
            roomId: 'C05',
            teachers: ['Sarah Johnson'],
            teacherIds: ['teacher-3'],
            teacherTokens: ['teacher-token-3'],
            courseId: 'course-3',
            courseToken: 'english-token',
            courseName: 'English CAE',
            status: 'confirmed',
            color: '#CC3333',
            eventType: 'lesson',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-4',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 10, 50),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 11, 40),
            text: 'Chemie Labor',
            comment: 'Titration von Essigsäure, Schutzbrille obligatorisch',
            roomToken: 'LAB1',
            roomId: 'LAB1',
            teachers: ['Tobias Graf'],
            teacherIds: ['teacher-4'],
            teacherTokens: ['teacher-token-4'],
            courseId: 'course-4',
            courseToken: 'chemie-token',
            courseName: 'Chemie Praktikum',
            status: 'confirmed',
            color: '#FFB300',
            eventType: 'lab',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-5',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 13, 15),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 13, 35),
            text: 'Wirtschaft & Recht',
            comment: 'Fallstudie Start-up Finanzierung',
            roomToken: 'EU2',
            roomId: 'EU2',
            teachers: ['Dieter Dürr'],
            teacherIds: ['teacher-5'],
            teacherTokens: ['teacher-token-5'],
            courseId: 'course-5',
            courseToken: 'wir-token',
            courseName: 'Wirtschaft & Recht',
            status: 'confirmed',
            color: '#8E24AA',
            eventType: 'lesson',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-6',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 13, 35),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 13, 50),
            text: 'Innovation Lab',
            comment: 'Projektarbeit am digitalen Prototypen',
            roomToken: 'LAB3',
            roomId: 'LAB3',
            teachers: ['Laura Frei'],
            teacherIds: ['teacher-6'],
            teacherTokens: ['teacher-token-6'],
            courseId: 'course-6',
            courseToken: 'innovation-token',
            courseName: 'Innovation Lab',
            status: 'confirmed',
            color: '#F4511E',
            eventType: 'lesson',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-7',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 14, 45),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 14, 50),
            text: 'Design Thinking',
            comment: 'Rapid prototyping für Schüler*innenideen',
            roomToken: 'C210',
            roomId: 'C210',
            teachers: ['Nina Kaufmann'],
            teacherIds: ['teacher-7'],
            teacherTokens: ['teacher-token-7'],
            courseId: 'course-7',
            courseToken: 'design-token',
            courseName: 'Design Thinking',
            status: 'confirmed',
            color: '#FF7043',
            eventType: 'project',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'demo-event-8',
            startDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 14, 55),
            endDate: DateTime(
                targetDate.year, targetDate.month, targetDate.day, 15, 00),
            text: 'Projektmanagement',
            comment: 'Agile Retrospektive & Aufgabenverteilung',
            roomToken: 'B108',
            roomId: 'B108',
            teachers: ['Felix Meyer'],
            teacherIds: ['teacher-8'],
            teacherTokens: ['teacher-token-8'],
            courseId: 'course-8',
            courseToken: 'pm-token',
            courseName: 'Projektmanagement',
            status: 'confirmed',
            color: '#26A69A',
            eventType: 'lesson',
            isExam: false,
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
      ];
    }
    // Extract base path without query parameters for switch matching
    final basePath = path.split('?').first;
    switch (basePath) {
      case '/rest/v1/me':
        return Student(
          id: "demo-student-1",
          userType: "student",
          idNr: "S123456",
          lastName: "Baumann",
          firstName: "Lina",
          loginActive: true,
          gender: "female",
          birthday: DateTime.now().subtract(const Duration(days: 17 * 365)),
          street: "Bielstrasse 12",
          zip: "4500",
          city: "Solothurn",
          nationality: "Schweiz",
          hometown: "Grenchen",
          phone: "032 511 22 11",
          mobile: "+41 79 555 44 33",
          email: "lina.baumann@kssolothurn.ch",
          emailPrivate: "lina.baumann@example.com",
          profil1: "EngW",
          entryDate: DateTime.now().subtract(const Duration(days: 530)),
          regularClasses: [
            const RegularClass(id: "3C", token: "3C-2023", semester: "3"),
            const RegularClass(id: "Chemie-Lab", token: "LAB1", semester: "3")
          ],
          additionalClasses: [
            const RegularClass(
                id: "English CAE", token: "ENG-CAE", semester: "3")
          ],
        );
      case '/rest/v1/me/exams':
        final examDate1 = DateTime.now().add(const Duration(days: 2));
        final examDate2 = DateTime.now().add(const Duration(days: 4));
        final examDate3 = DateTime.now().add(const Duration(days: 8));
        return [
          Exam(
              id: 'demo-exam-1',
              startDate: DateTime(
                  examDate1.year, examDate1.month, examDate1.day, 8, 0),
              endDate: DateTime(
                  examDate1.year, examDate1.month, examDate1.day, 9, 15),
              text: 'Ableitungen & Kurvendiskussion',
              comment: 'Hilfsmittel: Taschenrechner & Formular Sammlung',
              roomToken: 'B215',
              roomId: 'B215',
              teachers: ['Patrick Keller'],
              teacherIds: ['teacher-1'],
              teacherTokens: ['teacher-token-1'],
              courseId: 'course-1',
              courseToken: 'math-token',
              courseName: 'Mathematik Schwerpunkt',
              status: 'confirmed',
              color: '#3366CC',
              eventType: 'exam',
              eventRoomStatus: null,
              timetableText: null,
              infoFacilityManagement: null,
              importset: null,
              lessons: null,
              publishToInfoSystem: null,
              studentNames: null,
              studentIds: null),
          Exam(
              id: 'demo-exam-2',
              startDate: DateTime(
                  examDate2.year, examDate2.month, examDate2.day, 10, 5),
              endDate: DateTime(
                  examDate2.year, examDate2.month, examDate2.day, 11, 35),
              text: 'Geschichte - Bundesstaat Schweiz',
              comment: 'Essay + Quellenanalyse',
              roomToken: 'A112',
              roomId: 'A112',
              teachers: ['Claudia Messerli'],
              teacherIds: ['teacher-2'],
              teacherTokens: ['teacher-token-2'],
              courseId: 'course-2',
              courseToken: 'history-token',
              courseName: 'Geschichte 3C',
              status: 'confirmed',
              color: '#A0522D',
              eventType: 'exam',
              eventRoomStatus: null,
              timetableText: null,
              infoFacilityManagement: null,
              importset: null,
              lessons: null,
              publishToInfoSystem: null,
              studentNames: null,
              studentIds: null),
          Exam(
              id: 'demo-exam-3',
              startDate: DateTime(
                  examDate3.year, examDate3.month, examDate3.day, 13, 0),
              endDate: DateTime(
                  examDate3.year, examDate3.month, examDate3.day, 14, 30),
              text: 'English CAE Mock Listening',
              comment:
                  'Bring headphones, Prüfungssaal öffnet 15 Minuten vorher',
              roomToken: 'Aula',
              roomId: 'Aula',
              teachers: ['Sarah Johnson'],
              teacherIds: ['teacher-3'],
              teacherTokens: ['teacher-token-3'],
              courseId: 'course-3',
              courseToken: 'english-token',
              courseName: 'English CAE',
              status: 'confirmed',
              color: '#CC3333',
              eventType: 'exam',
              eventRoomStatus: null,
              timetableText: null,
              infoFacilityManagement: null,
              importset: null,
              lessons: null,
              publishToInfoSystem: null,
              studentNames: null,
              studentIds: null),
        ];

      case '/rest/v1/me/grades':
        return [
          Grade(
              course: "Wirtschaft & Recht",
              subject: "Wirtschaft & Recht",
              title: "Fallstudie Gütermarkt",
              date: DateTime.now().subtract(const Duration(days: 3)).toString(),
              mark: 5.5,
              weight: 1.5),
          Grade(
              course: "Wirtschaft & Recht",
              subject: "Wirtschaft & Recht",
              title: "Kennzahlen Analyse",
              date: DateTime.now().subtract(const Duration(days: 6)).toString(),
              mark: 5.0,
              weight: 1),
          Grade(
              course: "Mathematik Schwerpunkt",
              subject: "Mathematik",
              title: "Integralrechnung Quiz",
              date: DateTime.now().subtract(const Duration(days: 4)).toString(),
              mark: 4.8,
              weight: 1),
          Grade(
              course: "Deutsch",
              subject: "Deutsch",
              title: "Interpretation 'Die Physiker'",
              date: DateTime.now().subtract(const Duration(days: 7)).toString(),
              mark: 5.0,
              weight: 1),
          Grade(
              course: "Deutsch",
              subject: "Deutsch",
              title: "Sachtextanalyse Rhetorik",
              date:
                  DateTime.now().subtract(const Duration(days: 11)).toString(),
              mark: 4.7,
              weight: 1),
          Grade(
              course: "English CAE",
              subject: "English",
              title: "Essay Climate Change",
              date: DateTime.now().subtract(const Duration(days: 8)).toString(),
              mark: 5.8,
              weight: 1),
          Grade(
              course: "English CAE",
              subject: "English",
              title: "Vocabulary Test Unit 3",
              date:
                  DateTime.now().subtract(const Duration(days: 13)).toString(),
              mark: 5.4,
              weight: 0.5),
          Grade(
              course: "Chemie Praktikum",
              subject: "Chemie",
              title: "Protokoll Titration",
              date: DateTime.now().subtract(const Duration(days: 9)).toString(),
              mark: 5.2,
              weight: 2),
          Grade(
              course: "Chemie Praktikum",
              subject: "Chemie",
              title: "Säure-Base-Test",
              date:
                  DateTime.now().subtract(const Duration(days: 14)).toString(),
              mark: 4.9,
              weight: 1),
          Grade(
              course: "Französisch",
              subject: "Französisch",
              title: "Rédaction 'Mes vacances'",
              date:
                  DateTime.now().subtract(const Duration(days: 10)).toString(),
              mark: 4.4,
              weight: 1),
          Grade(
              course: "Französisch",
              subject: "Französisch",
              title: "Compréhension écrite B2",
              date:
                  DateTime.now().subtract(const Duration(days: 15)).toString(),
              mark: 5.1,
              weight: 1),
          Grade(
              course: "Mathematik Schwerpunkt",
              subject: "Mathematik",
              title: "Diagnose-Test Funktionen",
              date:
                  DateTime.now().subtract(const Duration(days: 12)).toString(),
              mark: 3.8,
              weight: 0.5),
        ];
      case '/rest/v1/me/absencenotices':
        return [
          Absence(
              id: "abs-001",
              date: DateTime.now().subtract(const Duration(days: 5)).toString(),
              course: "Chemie Praktikum",
              hourFrom: "10:50:00",
              hourTo: "11:40:00",
              status: "e"),
          Absence(
              id: "abs-002",
              date:
                  DateTime.now().subtract(const Duration(days: 13)).toString(),
              course: "Deutsch",
              hourFrom: "08:40:00",
              hourTo: "09:30:00",
              status: "o"),
          Absence(
              id: "abs-003",
              date:
                  DateTime.now().subtract(const Duration(days: 21)).toString(),
              course: "Sport",
              hourFrom: "15:00:00",
              hourTo: "16:30:00",
              status: "e")
        ];
      default:
        debugPrint('getDemoData: No demo data for path: $path');
        return null;
    }
  }

  Future<bool> isAccessTokenValid(String token, String targetSchool) async {
    if (token.isEmpty || targetSchool.isEmpty) {
      return false;
    }
    try {
      final urlString = '$_baseUrl/$targetSchool/rest/v1/me';
      final finalUrl =
          kIsWeb ? 'https://proxy.corsfix.com/?$urlString' : urlString;
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
        kIsWeb ? 'https://proxy.corsfix.com/?$urlString' : urlString;
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
