class Event {
  final String? id;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? text;
  final String? comment;
  final String? roomToken;
  final String? roomId;
  final List<String>? teachers;
  final List<String>? teacherIds;
  final List<String>? teacherTokens;
  final String? courseId;
  final String? courseToken;
  final String? courseName;
  final String? status;
  final String? color;
  final String? eventType;
  final String? eventRoomStatus;
  final dynamic timetableText;
  final dynamic infoFacilityManagement;
  final dynamic importset;
  final dynamic lessons;
  final dynamic publishToInfoSystem;
  final List<String>? studentNames;
  final List<String>? studentIds;
  bool isExam;

  Event({
    this.id,
    this.startDate,
    this.endDate,
    this.text,
    this.comment,
    this.roomToken,
    this.roomId,
    this.teachers,
    this.teacherIds,
    this.teacherTokens,
    this.courseId,
    this.courseToken,
    this.courseName,
    this.status,
    this.color,
    this.eventType,
    this.eventRoomStatus,
    this.timetableText,
    this.infoFacilityManagement,
    this.importset,
    this.lessons,
    this.publishToInfoSystem,
    this.studentNames,
    this.studentIds,
    this.isExam = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      text: json['text'],
      comment: json['comment'],
      roomToken: json['roomToken'],
      roomId: json['roomId'],
      teachers: json['teachers'] != null ? json['teachers'].cast<String>() : null,
      teacherIds: json['teacherIds'] != null ? json['teacherIds'].cast<String>() : null,
      teacherTokens: json['teacherTokens'] != null ? json['teacherTokens'].cast<String>() : null,
      courseId: json['courseId'],
      courseToken: json['courseToken'],
      courseName: json['courseName'],
      status: json['status'],
      color: json['color'],
      eventType: json['eventType'],
      eventRoomStatus: json['eventRoomStatus'],
      timetableText: json['timetableText'],
      infoFacilityManagement: json['infoFacilityManagement'],
      importset: json['importset'],
      lessons: json['lessons'],
      publishToInfoSystem: json['publishToInfoSystem'],
      studentNames: json['studentNames'] != null ? json['studentNames'].cast<String>() : null,
      studentIds: json['studentIds'] != null ? json['studentIds'].cast<String>() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['startDate'] = startDate?.toIso8601String();
    data['endDate'] = endDate?.toIso8601String();
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
