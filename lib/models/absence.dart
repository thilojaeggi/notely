class Absence {
  String? id;
  String? studentId;
  String? date;
  String? hourFrom;
  String? hourTo;
  String? status;
  String? comment;
  bool? isExamLesson;
  String? profile;
  String? course;
  String? absenceId;

  Absence(
      {String? id,
      String? studentId,
      String? date,
      String? hourFrom,
      String? hourTo,
      String? status,
      String? comment,
      bool? isExamLesson,
      String? profile,
      String? course,
      String? absenceId}) {
    if (id != null) {
      id = id;
    }
    if (studentId != null) {
      studentId = studentId;
    }
    if (date != null) {
      date = date;
    }
    if (hourFrom != null) {
      hourFrom = hourFrom;
    }
    if (hourTo != null) {
      hourTo = hourTo;
    }
    if (status != null) {
      status = status;
    }
    if (comment != null) {
      comment = comment;
    }
    if (isExamLesson != null) {
      isExamLesson = isExamLesson;
    }
    if (profile != null) {
      profile = profile;
    }
    if (course != null) {
      course = course;
    }
    if (absenceId != null) {
      absenceId = absenceId;
    }
  }

  Absence.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    date = json['date'];
    hourFrom = json['hourFrom'];
    hourTo = json['hourTo'];
    status = json['status'];
    comment = json['comment'];
    isExamLesson = json['isExamLesson'];
    profile = json['profile'];
    course = json['course'];
    absenceId = json['absenceId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentId'] = studentId;
    data['date'] = date;
    data['hourFrom'] = hourFrom;
    data['hourTo'] = hourTo;
    data['status'] = status;
    data['comment'] = comment;
    data['isExamLesson'] = isExamLesson;
    data['profile'] = profile;
    data['course'] = course;
    data['absenceId'] = absenceId;
    return data;
  }
}
