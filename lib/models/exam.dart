// To parse this JSON data, do
//
//     final Exam = ExamFromJson(jsonString);

class Exam {
  Exam({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.text,
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
  });

  String id;
  DateTime startDate;
  DateTime endDate;
  String text;
  dynamic comment;
  dynamic roomToken;
  dynamic roomId;
  dynamic teachers;
  dynamic teacherIds;
  dynamic teacherTokens;
  String courseId;
  String courseToken;
  String courseName;
  dynamic status;
  dynamic color;
  String eventType;
  dynamic eventRoomStatus;
  dynamic timetableText;
  dynamic infoFacilityManagement;
  dynamic importset;
  dynamic lessons;
  dynamic publishToInfoSystem;
  dynamic studentNames;
  dynamic studentIds;

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json["id"],
        startDate: DateTime.parse(json["startDate"]),
        endDate: DateTime.parse(json["endDate"]),
        text: json["text"],
        comment: json["comment"],
        roomToken: json["roomToken"],
        roomId: json["roomId"],
        teachers: json["teachers"],
        teacherIds: json["teacherIds"],
        teacherTokens: json["teacherTokens"],
        courseId: json["courseId"],
        courseToken: json["courseToken"],
        courseName: json["courseName"],
        status: json["status"],
        color: json["color"],
        eventType: json["eventType"],
        eventRoomStatus: json["eventRoomStatus"],
        timetableText: json["timetableText"],
        infoFacilityManagement: json["infoFacilityManagement"],
        importset: json["importset"],
        lessons: json["lessons"],
        publishToInfoSystem: json["publishToInfoSystem"],
        studentNames: json["studentNames"],
        studentIds: json["studentIds"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "startDate":
            "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
        "endDate":
            "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
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
      };
}
