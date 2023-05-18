import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notely/models/Absence.dart';
import 'package:notely/models/Event.dart';
import 'package:notely/models/exam.dart';
import 'package:notely/models/grade.dart';
import 'package:notely/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIClient {
  static final APIClient _singleton = APIClient._internal();
  static const String _baseUrl = 'https://kaschuso.so.ch/public';
  late String _accessToken;
  late String _school;
  bool _fakeData = false;

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

  set fakeData(bool fakeData) {
    _fakeData = fakeData;
  }

  String get school => _school;
  dynamic getDemoData(String path) {
    if (path.contains("events")) {
      return [
        Event(
            id: 'eeafsdg',
            startDate: DateTime.now().add(Duration(days: 7)),
            endDate: DateTime.now().add(Duration(days: 7)),
            text: 'Math',
            comment: 'Test',
            roomToken: 'A02',
            roomId: 'A02',
            teachers: ['Hans Müller'],
            teacherIds: ['1'],
            teacherTokens: ['1'],
            courseId: '1',
            courseToken: '1',
            courseName: 'Mathematik',
            status: '1',
            color: '1',
            eventType: '1',
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'sdfsfef',
            startDate: DateTime.now().add(Duration(days: 1)),
            endDate: DateTime.now().add(Duration(days: 1)),
            text: 'Math',
            comment: 'Test',
            roomToken: 'A02',
            roomId: 'A02',
            teachers: ['Hans Müller'],
            teacherIds: ['1'],
            teacherTokens: ['1'],
            courseId: '1',
            courseToken: '1',
            courseName: 'Mathematik',
            status: '1',
            color: '1',
            eventType: '1',
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: 'fhgfh',
            startDate: DateTime.now().add(Duration(days: 3)),
            endDate: DateTime.now().add(Duration(days: 3)),
            text: 'English',
            comment: 'Test',
            roomToken: 'B13',
            roomId: 'B13',
            teachers: ['Adriana Albrecht'],
            teacherIds: ['1'],
            teacherTokens: ['1'],
            courseId: '1',
            courseToken: '1',
            courseName: 'English',
            status: '1',
            color: '1',
            eventType: '1',
            eventRoomStatus: null,
            timetableText: null,
            infoFacilityManagement: null,
            importset: null,
            lessons: null,
            publishToInfoSystem: null,
            studentNames: null,
            studentIds: null),
        Event(
            id: '1',
            startDate: DateTime.now().add(Duration(days: 2)),
            endDate: DateTime.now().add(Duration(days: 2)),
            text: 'Math',
            comment: 'Test',
            roomToken: 'EU2',
            roomId: 'EU2',
            teachers: ['Dieter Dürr'],
            teacherIds: ['1'],
            teacherTokens: ['1'],
            courseId: '1',
            courseToken: '1',
            courseName: 'Wirtschaft und Recht',
            status: '1',
            color: '1',
            eventType: '1',
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
    switch (path) {
      case '/rest/v1/me':
        return Student(
            id: "test",
            idNr: "test",
            lastName: "Mustermann",
            firstName: "Max",
            loginActive: true,
            loginAd: true,
            gender: "male",
            birthday: DateTime.now(),
            street: "Musterstrasse 5",
            zip: "2545",
            city: "Selzach",
            nationality: "Schweiz",
            hometown: "Solothurn",
            phone: "0346424557565",
            mobile: "0346424557565",
            email: "max@mustermann.de",
            emailPrivate: "max@mustermann.de",
            profil1: "EngW",
            entryDate: DateTime.now().subtract(Duration(days: 7)),
            regularClasses: [
              RegularClass(id: "test", token: "test", semester: "3")
            ],
            additionalClasses: [
              "Demo",
              "Data"
            ]);
      case '/rest/v1/me/exams':
        return [
          Exam(
              id: '1',
              startDate: DateTime.now().add(Duration(days: 2)),
              endDate: DateTime.now().add(Duration(days: 2)),
              text: 'Trigonometrie',
              comment: '',
              roomToken: '1',
              roomId: '1',
              teachers: ['1'],
              teacherIds: ['1'],
              teacherTokens: ['1'],
              courseId: '1',
              courseToken: '1',
              courseName: 'Mathematik',
              status: '1',
              color: '1',
              eventType: '1',
              eventRoomStatus: null,
              timetableText: null,
              infoFacilityManagement: null,
              importset: null,
              lessons: null,
              publishToInfoSystem: null,
              studentNames: null,
              studentIds: null),
          Exam(
              id: '1',
              startDate: DateTime.now().add(Duration(days: 4)),
              endDate: DateTime.now().add(Duration(days: 4)),
              text: 'Pronouns and Prepositions',
              comment: '',
              roomToken: '1',
              roomId: '1',
              teachers: ['1'],
              teacherIds: ['1'],
              teacherTokens: ['1'],
              courseId: '1',
              courseToken: '1',
              courseName: 'English',
              status: '1',
              color: '1',
              eventType: '1',
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
              course: "Wirtschaft und Recht",
              subject: "Wirtschaft und Recht",
              title: "Welthandel und Wirtschaftspolitik",
              date: DateTime.now().subtract(Duration(days: 1)).toString(),
              mark: 6,
              weight: 1),
          Grade(
              course: "Mathematik",
              subject: "Mathematik",
              title: "Bogenmasse und Trigonometrie",
              date: DateTime.now().subtract(Duration(days: 1)).toString(),
              mark: 4.5,
              weight: 1),
          Grade(
              course: "Wirtschaft und Recht",
              subject: "Wirtschaft und Recht",
              title: "UNO und NATO",
              date: DateTime.now().subtract(Duration(days: 2)).toString(),
              mark: 6,
              weight: 1),
          Grade(
              course: "Französisch",
              subject: "Französisch",
              title: "Tests de grammaire",
              date: DateTime.now().subtract(Duration(days: 2)).toString(),
              mark: 5.5,
              weight: 1),
          Grade(
              course: "Mathematik",
              subject: "Mathematik",
              title: "Vektorrechnung",
              date: DateTime.now().subtract(Duration(days: 5)).toString(),
              mark: 3.5,
              weight: 1),
          Grade(
              course: "Französisch",
              subject: "Französisch",
              title: "Rédaction",
              date: DateTime.now().subtract(Duration(days: 5)).toString(),
              mark: 4.9,
              weight: 2),
        ];
      case '/rest/v1/me/absencenotices':
        return [
          Absence(
              id: "hfdg",
              date: DateTime.now().subtract(Duration(days: 5)).toString(),
              course: "Französisch",
              hourFrom: "11:10:00",
              hourTo: "11:55:00",
              status: "e")
        ];
    }
  }

  Future<T> get<T>(
      String path, T Function(dynamic) fromJson, bool cached) async {
    final prefs = await SharedPreferences.getInstance();
    if (_fakeData) {
      return getDemoData(path);
    }
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
          ? prefs.setString('$path', response.body)
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
          .where((e) => e.startDate.isAfter(today.subtract(Duration(days: 1))))
          .toList();
    }, cached);
  }

  Future<List<Event>> getEvents(DateTime date, bool cached) async {
    final dateFormatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    debugPrint(dateFormatted);
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

      return grades;
    }, cached);
  }

  Future<Student> getStudent(bool cached) async {
    return get('/rest/v1/me', (json) => Student.fromJson(json), cached);
  }
}
