class Absence {
  String? _id;
  String? _studentId;
  String? _date;
  String? _hourFrom;
  String? _hourTo;
  String? _status;
  String? _comment;
  bool? _isExamLesson;
  String? _profile;
  String? _course;
  String? _absenceId;

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
      this._id = id;
    }
    if (studentId != null) {
      this._studentId = studentId;
    }
    if (date != null) {
      this._date = date;
    }
    if (hourFrom != null) {
      this._hourFrom = hourFrom;
    }
    if (hourTo != null) {
      this._hourTo = hourTo;
    }
    if (status != null) {
      this._status = status;
    }
    if (comment != null) {
      this._comment = comment;
    }
    if (isExamLesson != null) {
      this._isExamLesson = isExamLesson;
    }
    if (profile != null) {
      this._profile = profile;
    }
    if (course != null) {
      this._course = course;
    }
    if (absenceId != null) {
      this._absenceId = absenceId;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get studentId => _studentId;
  set studentId(String? studentId) => _studentId = studentId;
  String? get date => _date;
  set date(String? date) => _date = date;
  set hourFrom(String? hourFrom) => _hourFrom = hourFrom;
  set hourTo(String? hourTo) => _hourTo = hourTo;
  set status(String? status) => _status = status;
  set comment(String? comment) => _comment = comment;
  set isExamLesson(bool? isExamLesson) => _isExamLesson = isExamLesson;
  set profile(String? profile) => _profile = profile;
  set course(String? course) => _course = course;
  set absenceId(String? absenceId) => _absenceId = absenceId;

  Absence.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _studentId = json['studentId'];
    _date = json['date'];
    _hourFrom = json['hourFrom'];
    _hourTo = json['hourTo'];
    _status = json['status'];
    _comment = json['comment'];
    _isExamLesson = json['isExamLesson'];
    _profile = json['profile'];
    _course = json['course'];
    _absenceId = json['absenceId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this._id;
    data['studentId'] = this._studentId;
    data['date'] = this._date;
    data['hourFrom'] = this._hourFrom;
    data['hourTo'] = this._hourTo;
    data['status'] = this._status;
    data['comment'] = this._comment;
    data['isExamLesson'] = this._isExamLesson;
    data['profile'] = this._profile;
    data['course'] = this._course;
    data['absenceId'] = this._absenceId;
    return data;
  }
}
