// ignoreforfile: prefervoidtonull

// ignore_for_file: prefer_void_to_null

class Event {
  String? id;
  DateTime? startDate;
  DateTime? endDate;
  String? text;
  String? comment;
  String? roomToken;
  String? roomId;
  List<String>? teachers;
  List<String>? teacherIds;
  List<String>? teacherTokens;
  String? courseId;
  String? courseToken;
  String? courseName;
  String? status;
  String? color;
  String? eventType;
  bool? isExam;
  Null eventRoomStatus;
  Null timetableText;
  Null infoFacilityManagement;
  Null importset;
  Null lessons;
  Null publishToInfoSystem;
  Null studentNames;
  Null studentIds;

  Event(
      {String? id,
      DateTime? startDate,
      DateTime? endDate,
      String? text,
      String? comment,
      String? roomToken,
      String? roomId,
      List<String>? teachers,
      List<String>? teacherIds,
      List<String>? teacherTokens,
      String? courseId,
      String? courseToken,
      String? courseName,
      String? status,
      String? color,
      String? eventType,
      bool? isExam,
      Null eventRoomStatus,
      Null timetableText,
      Null infoFacilityManagement,
      Null importset,
      Null lessons,
      Null publishToInfoSystem,
      Null studentNames,
      Null studentIds}) {
    if (id != null) {
      id = id;
    }
    if (startDate != null) {
      startDate = startDate;
    }
    if (endDate != null) {
      endDate = endDate;
    }
    if (text != null) {
      text = text;
    }
    if (comment != null) {
      comment = comment;
    }
    if (roomToken != null) {
      roomToken = roomToken;
    }
    if (roomId != null) {
      roomId = roomId;
    }
    if (teachers != null) {
      teachers = teachers;
    }
    if (teacherIds != null) {
      teacherIds = teacherIds;
    }
    if (teacherTokens != null) {
      teacherTokens = teacherTokens;
    }
    if (courseId != null) {
      courseId = courseId;
    }
    if (courseToken != null) {
      courseToken = courseToken;
    }
    if (courseName != null) {
      courseName = courseName;
    }
    if (status != null) {
      status = status;
    }
    if (color != null) {
      color = color;
    }
    if (eventType != null) {
      eventType = eventType;
    }
    if (isExam != null) {
      isExam = isExam;
    }
  }

  Event.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    startDate = DateTime.parse(json['startDate']);
    endDate = DateTime.parse(json['endDate']);
    text = json['text'];
    comment = json['comment'];
    roomToken = json['roomToken'];
    roomId = json['roomId'];
    teachers = json['teachers'].cast<String>();
    teacherIds = json['teacherIds'].cast<String>();
    teacherTokens = json['teacherTokens'].cast<String>();
    courseId = json['courseId'];
    courseToken = json['courseToken'];
    courseName = json['courseName'];
    status = json['status'];
    color = json['color'];
    eventType = json['eventType'];
    eventRoomStatus = json['eventRoomStatus'];
    timetableText = json['timetableText'];
    infoFacilityManagement = json['infoFacilityManagement'];
    importset = json['importset'];
    lessons = json['lessons'];
    publishToInfoSystem = json['publishToInfoSystem'];
    studentNames = json['studentNames'];
    studentIds = json['studentIds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['text'] = text;
    data['comment'] = comment;
    data['roomToken'] = roomToken;
    data['roomId'] = roomId;
    data['teachers'] = teachers;
    data['teacherIds'] = teacherIds;
    data['teacherTokens'] = teacherTokens;
    data['courseId'] = courseId;
    data['courseToken'] = courseToken;
    data['courseName'] = courseName;
    data['status'] = status;
    data['color'] = color;
    data['eventType'] = eventType;
    data['eventRoomStatus'] = eventRoomStatus;
    data['timetableText'] = timetableText;
    data['infoFacilityManagement'] = infoFacilityManagement;
    data['importset'] = importset;
    data['lessons'] = lessons;
    data['publishToInfoSystem'] = publishToInfoSystem;
    data['studentNames'] = studentNames;
    data['studentIds'] = studentIds;
    return data;
  }
}
