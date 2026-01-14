DateTime _parseExamDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return DateTime.now();
  }
  var normalized = raw.trim();
  if (!normalized.contains('T') && normalized.contains(' ')) {
    normalized = normalized.replaceFirst(' ', 'T');
  }
  if (RegExp(r'T\d{2}:\d{2}$').hasMatch(normalized)) {
    normalized = '$normalized:00';
  }
  return DateTime.parse(normalized);
}

DateTime? _tryParseExamDate(String? raw) {
  try {
    return _parseExamDate(raw);
  } catch (_) {
    return null;
  }
}

List<String>? _parseStringList(dynamic data) {
  if (data == null) return null;
  if (data is List) {
    return data
        .map((item) => item == null ? '' : item.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  final text = data.toString();
  return text.isEmpty ? null : [text];
}

String? _formatExamDate(DateTime? value) => value?.toIso8601String();

class Exam {
  const Exam({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.text,
    this.comment,
    this.roomToken,
    this.roomId,
    this.teachers,
    this.teacherIds,
    this.teacherTokens,
    required this.courseId,
    required this.courseToken,
    required this.courseName,
    this.status,
    this.color,
    required this.eventType,
    this.eventRoomStatus,
    this.timetableText,
    this.infoFacilityManagement,
    this.importset,
    this.lessons,
    this.publishToInfoSystem,
    this.studentNames,
    this.studentIds,
    this.client,
    this.clientName,
    this.weight,
    this.absTrackedTimestamp,
  });

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String? text;
  final String? comment;
  final String? roomToken;
  final String? roomId;
  final List<String>? teachers;
  final List<String>? teacherIds;
  final List<String>? teacherTokens;
  final String courseId;
  final String courseToken;
  final String courseName;
  final String? status;
  final String? color;
  final String eventType;
  final String? eventRoomStatus;
  final String? timetableText;
  final String? infoFacilityManagement;
  final dynamic importset;
  final dynamic lessons;
  final dynamic publishToInfoSystem;
  final List<String>? studentNames;
  final List<String>? studentIds;
  final String? client;
  final String? clientName;
  final int? weight;
  final DateTime? absTrackedTimestamp;

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json["id"] ?? '',
        startDate: _parseExamDate(json["startDate"]),
        endDate: _parseExamDate(json["endDate"]),
        text: json["text"],
        comment: json["comment"],
        roomToken: json["roomToken"],
        roomId: json["roomId"],
        teachers: _parseStringList(json["teachers"]),
        teacherIds: _parseStringList(json["teacherIds"]),
        teacherTokens: _parseStringList(json["teacherTokens"]),
        courseId: json["courseId"] ?? '',
        courseToken: json["courseToken"] ?? '',
        courseName: json["courseName"] ?? '',
        status: json["status"],
        color: json["color"],
        eventType: json["eventType"] ?? '',
        eventRoomStatus: json["eventRoomStatus"],
        timetableText: json["timetableText"],
        infoFacilityManagement: json["infoFacilityManagement"],
        importset: json["importset"],
        lessons: json["lessons"],
        publishToInfoSystem: json["publishToInfoSystem"],
        studentNames: _parseStringList(json["studentNames"]),
        studentIds: _parseStringList(json["studentIds"]),
        client: json["client"],
        clientName: json["clientname"],
        weight: (json["weight"] is num) ? (json["weight"] as num).toInt() : null,
        absTrackedTimestamp: _tryParseExamDate(json["absTrackedTimestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "startDate": _formatExamDate(startDate),
        "endDate": _formatExamDate(endDate),
        "text": text,
        "comment": comment,
        "roomToken": roomToken,
        "roomId": roomId,
        "teachers": teachers,
        "teacherIds": teacherIds,
        "teacherTokens": teacherTokens,
        "courseId": courseId,
        "courseToken": courseToken,
        "courseName": courseName,
        "status": status,
        "color": color,
        "eventType": eventType,
        "eventRoomStatus": eventRoomStatus,
        "timetableText": timetableText,
        "infoFacilityManagement": infoFacilityManagement,
        "importset": importset,
        "lessons": lessons,
        "publishToInfoSystem": publishToInfoSystem,
        "studentNames": studentNames,
        "studentIds": studentIds,
        "client": client,
        "clientname": clientName,
        "weight": weight,
        "absTrackedTimestamp": _formatExamDate(absTrackedTimestamp),
      };
}
