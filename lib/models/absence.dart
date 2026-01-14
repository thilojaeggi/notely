// ignore: file_names
// this is probably a bug since the file is definitely not capitalized
class Absence {
  String? id;
  String? studentId;
  String? date;
  String? hourFrom;
  String? hourTo;
  String? status;
  String? statusLong;
  String? comment;
  bool? isExamLesson;
  String? profile;
  String? course;
  String? absenceId;

  Absence(
      {this.id,
      this.studentId,
      this.date,
      this.hourFrom,
      this.hourTo,
      this.status,
      this.statusLong,
      this.comment,
      this.isExamLesson,
      this.profile,
      this.course,
      this.absenceId});

  Absence.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    date = json['date'];
    hourFrom = json['hourFrom'];
    hourTo = json['hourTo'];
    status = json['status'];
    statusLong = json['statusLong'];
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
    data['statusLong'] = statusLong;
    data['comment'] = comment;
    data['isExamLesson'] = isExamLesson;
    data['profile'] = profile;
    data['course'] = course;
    data['absenceId'] = absenceId;
    return data;
  }
}
